#!/bin/bash
# Description: This script automates the process of committing changes in batches, pushing to new branches,
#              and opening draft pull requests on GitHub for each batch.
# Author:      ledped (https://github.com/ledped/)

# Assumptions:
# 1. Git is configured properly, including authentication, etc.
# 2. All changes to files have been made locally and saved but not yet staged ("git add") or committed.  
# 3. All files that have changes that need to be committed are listed in "list.txt" with path relative to repo root.
# 4. Both this script, as well as "list.txt" are in repo root.
# 5. Before running this script, the main branch is checked out and updated against remote ("git checkout ${main_branch}" + "git pull").

# Initialize variables
batch_size=150
counter=1
branch_prefix="JIRA-NUMBER-description-part-"
commit_message_prefix="refactor(module): description part-"
repo_url="git@github.com:MyOrganization/my-infra.git"  # Replace with your GitHub repository URL
pr_title_prefix="refactor(module): description part-"
main_branch="master"  # or "main" if that's the name of your default branch

# Read the list of files
file_list=( $(<list.txt) )

# Function to create a branch, commit changes, push, and open a PR
create_pr() {
    local part_num=$1
    local files_to_commit=("${!2}")

    branch_name="${branch_prefix}${part_num}"
    commit_message="${commit_message_prefix}${part_num}"
    pr_title="${pr_title_prefix}${part_num}"

    # Checkout new branch from the remote main/master branch
    git checkout $main_branch

    # Create a new branch
    git checkout -b "$branch_name"

    # Add the files and commit
    git add "${files_to_commit[@]}"
    git commit -m "$commit_message"

    # Push the branch
    git push -u origin "$branch_name"

    # Open a draft pull request
    gh pr create --title "$pr_title" --body "$commit_message" --base $main_branch --head "$branch_name" --draft
}

# Split the files into batches and create PRs for each batch
for ((i=0; i<${#file_list[@]}; i+=batch_size)); do
    batch=( "${file_list[@]:i:batch_size}" )
    create_pr "$counter" batch[@]
    counter=$((counter + 1))
done

# Checkout back to the main branch
git checkout $main_branch
