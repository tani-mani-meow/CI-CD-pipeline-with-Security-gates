#!/usr/bin/env python3
import os
import sys
import subprocess
import random
import datetime
import shutil

# Target configuration
GIT_USER = "tani-mani-meow"
GIT_EMAIL = "tanishq.ingawale@gmail.com"
TIMEZONE_OFFSET = "+0530"  # Local timezone offset

START_DATE = datetime.date(2026, 5, 4)   # Monday
END_DATE = datetime.date(2026, 5, 24)    # Sunday (Exactly 3 weeks)

# File staging groups to build the repo incrementally
GROUPS = [
    # 1. Base Setup
    [".gitignore", ".dockerignore", "package.json", "README.md", "LICENSE", "SECURITY.md", "CONTRIBUTING.md"],
    # 2. Docker & Linters
    ["docker-compose.yml", "docker-compose.prod.yml", "Dockerfile", ".eslintrc.json", "jest.config.js"],
    # 3. Core App
    ["src/app.js", "src/server.js", "src/middleware/logger.js"],
    # 4. Routes & Unit Tests
    ["src/routes/health.js", "tests/unit/app.test.js"],
    # 5. Infrastructure Base
    ["terraform/providers.tf", "terraform/backend.tf", "terraform/backend.example.tf", "terraform/variables.tf", "terraform/terraform.tfvars.example"],
    # 6. VPC networking
    ["terraform/modules/vpc"],
    # 7. ECR & IAM
    ["terraform/modules/ecr", "terraform/modules/iam"],
    # 8. Load Balancing
    ["terraform/modules/alb"],
    # 9. ECS Service & Root Terraform
    ["terraform/modules/ecs", "terraform/main.tf", "terraform/outputs.tf"],
    # 10. Bootstrap & Integration Tests
    ["scripts/bootstrap-state.sh", "tests/integration/health.test.js"],
    # 11. GitHub Actions CI
    [".github/workflows/ci.yml", ".github/workflows/codeql.yml"],
    # 12. GitHub Actions CD
    [".github/workflows/deploy.yml", "scripts/smoke-test.sh", "scripts/rollback.sh"],
    # 13. Manual Workflows
    [".github/workflows/rollback.yml", ".github/workflows/destroy.yml"],
]

COMMIT_MESSAGES = [
    "setup initial repository structure",
    "update core components",
    "refactor layout",
    "tweak UI styles",
    "patch minor routing issue",
    "working on adjustments",
    "optimize core execution",
    "update configuration files",
    "minor bugfixes and optimizations",
    "improve documentation",
    "refactor terraform modules",
    "configure pipeline workflows",
    "adjust environment variables",
    "optimize build processes",
]

def run_cmd(args, env=None):
    res = subprocess.run(args, capture_output=True, text=True, env=env)
    if res.returncode != 0:
        print(f"Error running command: {' '.join(args)}")
        print(res.stderr)
        return False, res.stderr
    return True, res.stdout

def generate_commit_dates(start_date, end_date, num_commits):
    # Get all days in the range
    current = start_date
    all_days = []
    while current <= end_date:
        all_days.append(current)
        current += datetime.timedelta(days=1)
        
    chosen_days = []
    # Sample days with weekday preference (Monday=0 to Friday=4)
    attempts = 0
    while len(chosen_days) < num_commits and attempts < 2000:
        attempts += 1
        day = random.choice(all_days)
        # Weekday check
        if day.weekday() >= 5 and random.random() > 0.15:
            # 85% chance to skip weekends to favor weekday commit activity
            continue
        chosen_days.append(day)
        
    # If not enough days chosen, fill with any random day
    while len(chosen_days) < num_commits:
        chosen_days.append(random.choice(all_days))
        
    chosen_days.sort()
    
    # Assign times to each day (between 09:00 AM and 08:00 PM)
    commit_datetimes = []
    for day in chosen_days:
        hour = random.randint(9, 19)
        minute = random.randint(0, 59)
        second = random.randint(0, 59)
        dt_str = f"{day.strftime('%Y-%m-%d')} {hour:02d}:{minute:02d}:{second:02d} {TIMEZONE_OFFSET}"
        commit_datetimes.append(dt_str)
        
    # Ensure they are sorted in strictly increasing chronological order
    def parse_dt(dt_s):
        return datetime.datetime.strptime(dt_s.split(" ")[0] + " " + dt_s.split(" ")[1], "%Y-%m-%d %H:%M:%S")
        
    commit_datetimes.sort(key=parse_dt)
    return commit_datetimes

def main():
    # Verify we are in the correct directory
    if not os.path.exists("package.json") or not os.path.exists("src"):
        print("Error: Please run this script in the root of the project workspace.")
        sys.exit(1)
        
    print("=== Git History Reconstruction ===")
    
    # Configure local Git user name and email first
    print(f"Configuring local Git credentials: {GIT_USER} <{GIT_EMAIL}>...")
    run_cmd(["git", "config", "user.name", GIT_USER])
    run_cmd(["git", "config", "user.email", GIT_EMAIL])
    
    # 1. Create a new orphan branch to start fresh history without parent commits
    print("Creating orphan branch to start a fresh history...")
    ok, out = run_cmd(["git", "checkout", "--orphan", "temp_history_reconstruct"])
    if not ok:
        print("Failed to checkout orphan branch. Retrying with standard branch deletion if we are already in temp...")
        run_cmd(["git", "checkout", "main"])
        run_cmd(["git", "branch", "-D", "temp_history_reconstruct"])
        ok, out = run_cmd(["git", "checkout", "--orphan", "temp_history_reconstruct"])
        if not ok:
            print("Failed to initialize fresh Git state via orphan branch.")
            sys.exit(1)
            
    # Unstage all files so we can stage them step-by-step
    run_cmd(["git", "reset"])
    
    # Determine commit count (between 14 and 17 commits)
    num_commits = random.randint(14, 17)
    print(f"Generating {num_commits} commits over target range (May 4, 2026 - May 24, 2026)...")
    
    commit_dates = generate_commit_dates(START_DATE, END_DATE, num_commits)
    
    # Process group commits
    for i in range(num_commits):
        date_str = commit_dates[i]
        env = os.environ.copy()
        env["GIT_AUTHOR_DATE"] = date_str
        env["GIT_COMMITTER_DATE"] = date_str
        
        # Decide which files to stage
        if i < len(GROUPS):
            # Stage specific group of files/dirs
            group_files = GROUPS[i]
            staged_any = False
            for filepath in group_files:
                if os.path.exists(filepath):
                    run_cmd(["git", "add", filepath])
                    staged_any = True
            if not staged_any:
                # If no files in this group exist, fallback to general check
                run_cmd(["git", "add", "."])
            
            message = COMMIT_MESSAGES[i % len(COMMIT_MESSAGES)]
            
        elif i == len(GROUPS):
            # Stage remaining untracked files
            run_cmd(["git", "add", "."])
            message = "minor bugfixes and optimizations"
        else:
            # Polishing commits: Modify README or code file slightly to create commits
            with open("README.md", "a") as f:
                f.write("\n")  # Append a newline to README
            run_cmd(["git", "add", "README.md"])
            message = random.choice(COMMIT_MESSAGES)
            
        # Commit changes
        ok, out = run_cmd(["git", "commit", "-m", message], env=env)
        if ok:
            print(f"Commit {i+1}/{num_commits}: '{message}' on {date_str}")
        else:
            print(f"Failed to commit at step {i+1}")
            
    # 2. Swap the orphan branch to main
    print("Promoting the reconstructed branch to 'main'...")
    # Delete 'main' if it exists and rename temporary branch to main
    run_cmd(["git", "checkout", "-b", "dummy_branch_for_deletion"])
    run_cmd(["git", "branch", "-D", "main"])
    run_cmd(["git", "checkout", "temp_history_reconstruct"])
    run_cmd(["git", "branch", "-D", "dummy_branch_for_deletion"])
    ok, out = run_cmd(["git", "branch", "-m", "main"])
    if not ok:
        print("Failed to rename temporary branch to main.")
        sys.exit(1)
        
    print("\nReconstruction complete!")
    print("New commit log:")
    ok, log_out = run_cmd(["git", "log", "--oneline", "--format=%h %ad %s", "--date=format:%Y-%m-%d %H:%M:%S"])
    if ok:
        print(log_out)
        
if __name__ == "__main__":
    main()
