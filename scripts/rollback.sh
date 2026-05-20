#!/usr/bin/env bash
set -euo pipefail

TASK_REVISION="${1:?Error: Task revision is required. Usage: ./rollback.sh <revision> [cluster] [service]}"
ECS_CLUSTER="${2:-cicd-pipeline-staging}"
ECS_SERVICE="${3:-cicd-pipeline-staging}"
TASK_FAMILY="${ECS_SERVICE}"
AWS_REGION="${AWS_REGION:-us-east-1}"

log() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"; }
err() { echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] ERROR: $*" >&2; }

log "=== ECS ROLLBACK ==="
log "Task:    ${TASK_FAMILY}:${TASK_REVISION}"
log "Cluster: $ECS_CLUSTER"
log "Service: $ECS_SERVICE"
log ""

TASK_ARN="${TASK_FAMILY}:${TASK_REVISION}"

log "Validating task definition exists..."
if ! aws ecs describe-task-definition --task-definition "$TASK_ARN" --region "$AWS_REGION" > /dev/null 2>&1; then
  err "Task definition not found: $TASK_ARN"
  err ""
  err "Available revisions:"
  aws ecs list-task-definitions --family-prefix "$TASK_FAMILY" --sort DESC --max-items 10 --region "$AWS_REGION"
  exit 1
fi
log "  Task definition found"

log "Updating ECS service..."
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$ECS_SERVICE" \
  --task-definition "$TASK_ARN" \
  --force-new-deployment \
  --region "$AWS_REGION" \
  --output text > /dev/null

log "Waiting for service to stabilise..."
aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --region "$AWS_REGION"

log "Running health check..."

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?contains(LoadBalancerName, '${ECS_CLUSTER}')].DNSName" \
  --output text \
  --region "$AWS_REGION")

if [ -z "$ALB_DNS" ]; then
log "Could not determine ALB DNS — skipping health check"
log "Rollback deployed (verify manually)"
  exit 0
fi

for attempt in $(seq 1 5); do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout 10 --max-time 30 \
    "http://$ALB_DNS/health" 2>/dev/null) || HTTP_STATUS="000"

  if [ "$HTTP_STATUS" = "200" ]; then
    log ""
    log "Rollback successful — service is healthy (HTTP $HTTP_STATUS)"
    log "   Task: ${TASK_FAMILY}:${TASK_REVISION}"
    log "   URL:  http://$ALB_DNS"
    exit 0
  fi

  log "  Attempt $attempt/5: HTTP $HTTP_STATUS, retrying in 10s..."
  sleep 10
done

err ""
err "ROLLBACK HEALTH CHECK FAILED"
err "   The service may still be starting. Check:"
err "   • aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE"
err "   • aws logs tail /ecs/${TASK_FAMILY}"
exit 1
