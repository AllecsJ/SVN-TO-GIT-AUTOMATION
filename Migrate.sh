#!/usr/bin/bash
#------------------config---------------------
username=("alex Jackson") #username
email=("alex_jackson@jmmb.com") #emaill 

git config --global user.name $username
git config --global user.email $email
git config --global user.password Ihaveanote600!
git config --global init.defaultBranch main
git config --global core.eol lf
git config --global core.autocrlf input
git config --global pack.packSizeLimit 1g
git config --global pack.deltaCacheSize 1g
git config --global pack.windowMemory 1g
git config --global core.packedGitLimit 1g
git config --global core.packedGitWindowSize 1g
#------------------config---------------------

echo "what gitlab group are you migrating to? (enterprise-applications || git-migration-test )"
read project

echo "What repo type would you like to migrate?"
echo "no branches: nb , has branches: hb, all repo: ar, other: any key"
read migration_type


#SELECTING MIGRATION TYPE
if [ $migration_type = 'nb' ]; then
    echo "Branchless repositories will be migrated now. "
    repo_list="no_branches.csv"
else
    if [ $migration_type = 'hb' ]; then
        echo "Repositories with branches will be migrated now. "
        repo_list="has_branches.csv"
    else
        if [ $migration_type = 'ar' ]; then
            echo "All repositroeis will be migrated now"
            repo_list="all_repos.csv"
        else
            echo "Enter a specific csv file that you would like to migrate. example.csv || non_standard_repo.csv || failed_repo.csv"
            read repo_list
            echo "$repo_list was entered."
        fi
    fi
fi



#STARTING MIGRATION
while IFS="," read -r repo_name repo_description repo_Status repo_type; do

    cd /workspace/libs
    #trim extra spaces from file
    repo_name=${repo_name//$'\r'} 
    # svn repository here
    URL=("http://monaco:9000/svn/$repo_name") 

    echo "------------------ migrating $repo_name ------------------" >> log.txt >> error_log.txt

    #checking if repository is null
    if [[ -z "$(svn ls $URL)" ]]; then
            echo "$repo_name is empty. Not migrated"
            status="Not Migrated - Empty Repo"
        else
            # Check if svn ls URL contains "trunk"
        if [[ "$(svn ls $URL)" != *"trunk"*  && "$(svn ls $URL)" != *"branches"*  &&  "$(svn ls $URL)" != *"tags"* ]]; then
                     #check for additonal folders
                folders=($(svn ls $URL | grep -v --invert-match "branches" | grep -v --invert-match "trunk" | grep -v --invert-match "tags" | awk '{gsub("","");print $1}')) 

                for folder in "${folders[@]}" 
                do
                    echo "additional branches"
                    echo "--branches=\"$folder\""  
                    non_std_branches=("--branches=\"$folder\"")   
                    join_folders="$join_folders $non_std_branches"
                done

                    echo "$repo_name is None standard. Manual Steps involved."
                    status="Not Migrated - Non standard repo"
                    echo "$repo_name, $repo_description, $repo_Status, $repo_type" >> non_standard_repo.csv
                    cd migClone/
                    #Clone Repository
                    echo "Cloning non standard repo $repo_name"
                    git svn clone --authors-file Authors.txt $URL $repo_name $join_folders

                    #navigate to dir where folder was created
                cd $repo_name/ 

                git add .
                
                #echo "creating description md" 
                if [[ -z $repo_description ]]; then
                echo "no description for $repo_name - no description.md file will be created."
                else
                git switch main 
                touch description.md   #create a .md file
                git add description.md   #add .md file to repo
                fi

                git commit -m "Migrated: added .gitignore file to $repo_name | and description.md file added. $repo_description"

                #add .gitignore file to empty repositories so they can be migrated.
                find ./ -empty -type d -exec touch {}/.gitignore \;
                git add .
                git commit -m "Added .gitignore file to empty folder" >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)


                #Clean the new Git repository
                #java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar clean-git  
                java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar clean-git --force  
                #------------------convert End---------------------
                
                #------------------Synchronize---------------------
                #Update the authors file
                git config svn.authorsfile  

                #Fetch the new SVN commits
                #Fetch the new SVN commits  

                #Synchronize with the fetched commits
                java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar sync-rebase  

                #Clean up the Git repo (again)
                java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar clean-git --force  
                #------------------Synchronize End---------------------
                
                #------------------Migrate-----------------------------
                #Synchronize the Git repository
                git svn fetch java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar sync-rebase java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar clean-git --force   

                #------------------Migrate End---------------------

                echo "creating $repo_name in group: $project."
                #create project in group
                git push --set-upstream git@gitlab.jmmb.com:$project/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD) 
                #remote origin url
                remoteOrigin=("git@gitlab.jmmb.com:$project/$repo_name.git")  
                #git remote add origin $remoteOrigin #runs the git remote command
                git remote add origin $remoteOrigin

                branch_name=($(git branch -a | grep -v --invert-match remotes/origin/tags/ | grep -v --invert-match "@" | awk '{gsub("remotes/origin/","");print $1}')) 
                tag_name=($(git branch -a | grep remotes/origin/tags/ | grep -v --invert-match "@" | grep -v HEAD | awk '{gsub("remotes/origin/tags/","");print $1}')) 

                #change the default branch
                git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main 
                #change the default branch
                #git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
                #Update your local repository to track the new main branch:


                #loop through the branches
                echo "looping through branches" 
                for branch in "${branch_name[@]}" 
                do
                    echo "git checkout - branch"  
                    git checkout -b $branch origin/$branch >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)
                done
                git push --all >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)

                echo "git tag" 
                git tag 
                #loop through the tags
                echo "looping through tags" 
                echo "git checkout- tags" 
                for tag in "${tag_name[@]}" 
                do             
                    git checkout origin/tags/$tag #

                    echo "git tag -a tag -m "creating tag"" 
                    git tag -a $tag -m "migrated tag"  >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)
                done  
                    git push --tags >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)
                status="migrated"

                cd /workspace/libs/

             
            else ## all standard repos
                #migrate all other repositories  

                #check for additonal folders
                folders=($(svn ls $URL | grep -v --invert-match "branches" | grep -v --invert-match "trunk" | grep -v --invert-match "tags" | awk '{gsub("","");print $1}')) 

                for folder in "${folders[@]}" 
                do
                    echo "additional branches"
                    echo "--branches=\"$folder\""  
                    non_std_branches=("--branches=\"$folder\"")   
                    join_folders="$join_folders $non_std_branches"
                done

                

                cd migClone/
                #Clone the SVN repository
                git svn clone -r1:HEAD --no-minimize-url --stdlayout --no-metadata --authors-file Authors.txt $URL --trunk="trunk" --branches="branches/" $join_folders  --tags="tags/"

                #navigate to dir where folder was created
                cd $repo_name/ 

                git add .
                
                #echo "creating description md" 
                if [[ -z $repo_description ]]; then
                echo "no description for $repo_name - no description.md file will be created."
                else
                git switch main 
                touch description.md   #create a .md file
                git add description.md   #add .md file to repo
                fi

                git commit -m "Migrated: added .gitignore file to $repo_name | and description.md file added. $repo_description"

                #add .gitignore file to empty repositories so they can be migrated.
                find ./ -empty -type d -exec touch {}/.gitignore \;
                git add .
                git commit -m "Added .gitignore file to empty folder" >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)


                #Clean the new Git repository
                #java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar clean-git  
                java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar clean-git --force  
                #------------------convert End---------------------
                
                #------------------Synchronize---------------------
                #Update the authors file
                git config svn.authorsfile  

                #Fetch the new SVN commits
                #Fetch the new SVN commits  

                #Synchronize with the fetched commits
                java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar sync-rebase  

                #Clean up the Git repo (again)
                java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar clean-git --force  
                #------------------Synchronize End---------------------
                
                #------------------Migrate-----------------------------
                #Synchronize the Git repository
                git svn fetch java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar sync-rebase java -Dfile.encoding=utf-8 -jar ~/svn-migration-scripts.jar clean-git --force   

                #------------------Migrate End---------------------

                echo "creating $repo_name in group: $project."
                #create project in group
                git push --set-upstream git@gitlab.jmmb.com:$project/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD) 
                #remote origin url
                remoteOrigin=("git@gitlab.jmmb.com:$project/$repo_name.git")  
                #git remote add origin $remoteOrigin #runs the git remote command
                git remote add origin $remoteOrigin

                branch_name=($(git branch -a | grep -v --invert-match remotes/origin/tags/ | grep -v --invert-match "@" | awk '{gsub("remotes/origin/","");print $1}')) 
                tag_name=($(git branch -a | grep remotes/origin/tags/ | grep -v --invert-match "@" | grep -v HEAD | awk '{gsub("remotes/origin/tags/","");print $1}')) 

                #change the default branch
                git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main 
                git checkout -b main origin/trunk
                #git fetch origin
                #git checkout origin/main
                #git merge --no-ff trunk
                #git push -u origin main 
                #change the default branch
                #git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
                #Update your local repository to track the new main branch:
                #git fetch origin 
                #git branch --set-upstream-to=origin/main main 

                #loop through the branches
                echo "looping through branches" 
                for branch in "${branch_name[@]}" 
                do
                    echo "git checkout - branches"  
                    git checkout -b $branch origin/$branch >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)
                    #git pull origin $branch     
                    #git push origin $branch           
                done
                #git fetch origin main
                #git pull    
                git push --all >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)

                echo "git tag" 
                git tag 
                #loop through the tags
                echo "looping through tags" 
                echo "git checkout- tags" 
                for tag in "${tag_name[@]}" 
                do             
                    git checkout origin/tags/$tag #

                    echo "git tag -a tag -m "creating tag"" 
                    git tag -a $tag -m "migrated tag"  >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)
                done  
                    git push --tags >> >(while read line; do echo "$(date): $line"; done >> ../../log.txt) 2>  >(while read line; do echo "$(date): $line"; done >> ../../error_log.txt)
                status="migrated"

        fi
    fi
    cd /workspace/libs/
    echo "------------------$repo_name migration complete ------------------" >> log.txt >> error_log.txt
    echo "$repo_name, $status" >> migration_results.txt  
    echo "$repo_name, $repo_description, $repo_Status, $repo_type" >> completed_repositories.txt
done < "$repo_list"       


