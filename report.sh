#!/usr/bin/bash
#------------------config---------------------
echo "What repo type would you like to migrate?"
echo "no branches: nb , has branches: hb, all repo: ar"
read report_type


#SELECTING MIGRATION TYPE
if [ $report_type = 'nb' ]; then
    echo "Branchless repositories will be checked now. "
    repo_list="no_branches.csv"
else
    if [ $report_type = 'hb' ]; then
        echo "Repositories with branches will be checked now. "
        repo_list="has_branches.csv"
    else
        if [ $report_type = 'ar' ]; then
            echo "All repositroeis will be checked now"
            repo_list="all_repos.csv"
        else
            echo "Input not recognized."
            echo "Enter a specific csv file that you would like to check. example.csv"
            read repo_list
            echo "$repo_list was entered. Continue?"
        fi
    fi
fi

#STARTING MIGRATION
while IFS="," read -r repo_name repo_description repo_Status repo_type; do

    #trim extra spaces from file
    repo_name=${repo_name//$'\r'} 
    # svn repository here
    URL=("http://monaco:9000/svn/$repo_name") 

    #checking if repository is null
    if [[ -z "$(svn ls $URL)" ]]; then
            echo "$repo_name is empty. Not migrated"
            status="Not Migrated - Empty Repo"
                echo "$repo_name, $repo_description, $repo_Status, $repo_type, $status" >> migration_report.csv 
                echo "$repo_name, $repo_description, $repo_Status, $repo_type" >> empty_repo.csv     
        else
            # Check if svn ls URL contains "trunk"
        if [[ "$(svn ls $URL)" != *"trunk"*  && "$(svn ls $URL)" != *"branches"*  &&  "$(svn ls $URL)" != *"tags"* ]]; then
                echo "$repo_name is None standard. Manual Steps involved."
                status="Not Migrated - Non standard repo | Manual Steps involved."
                echo "$repo_name, $repo_description, $repo_Status, $repo_type, $status" >> migration_report.csv 
                echo "$repo_name, $repo_description, $repo_Status, $repo_type" >> non_standard_repo.csv    
            else
                status="Migrated. Run diff"
                echo "$repo_name, $repo_description, $repo_Status, $repo_type, $status" >> migration_report.csv    
        fi
    fi

done < "$repo_list"       
