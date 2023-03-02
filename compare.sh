#!/bin/bash

function clone (){ 
    cd /workspace/libs/

    while IFS="," read -r repo_name repo_description repo_Status repo_type; do

        cd /workspace/libs/gitCompare/
        mkdir $project

        echo "Cloning git repo from $1: $repo_name"
        cd /workspace/libs/gitCompare/$project

        git clone git@gitlab.jmmb.com:$2/$repo_name.git -b main --single-branch $repo_name

        cd /workspace/libs/svnCompare
        mkdir $project
        echo "Exporting svn trunk for: $repo_name"
        cd /workspace/libs/svnCompare/$project

        svn export http://monaco:9000/svn/$repo_name/trunk --force $repo_name

    done < "$1"
        echo "All files downloaded"
        echo "Running diff now"
}

function compare (){

    while IFS="," read -r repo_name repo_description repo_Status repo_type; do
    cd /workspace/libs/

    git_dir=/workspace/libs/gitCompare/$project/$repo_name/
    svn_dir=/workspace/libs/svnCompare/$project/$repo_name/

    echo "$repo_name: "
    # show files that are different only
    cmd=`diff -rqNEZBi --strip-trailing-cr --ignore-trailing-space --exclude=.gitignore  --exclude=.git --exclude=$repo_name/.git --exclude=$repo_name/svn --exclude=description.md   $git_dir $svn_dir`
    echo " "
    echo "$repo_name: " >> $project-comparison_report.txt
    if  diff -rqNEZBi --strip-trailing-cr --ignore-trailing-space --exclude=.gitignore  --exclude=.git --exclude=$repo_name/.git --exclude=$repo_name/svn --exclude=description.md   $git_dir $svn_dir >> $project-comparison_report.txt; then
    echo "No differences found: Migrated sucessfully." >> $project-comparison_report.txt
    else
    diff -rqNEZBi --strip-trailing-cr --ignore-trailing-space --exclude=.gitignore  --exclude=.git --exclude=$repo_name/.git --exclude=$repo_name/svn --exclude=description.md   $git_dir $svn_dir >> $project-comparison_report.txt
    echo "$repo_name, $repo_description, $repo_Status, $repo_type" >> $project-failed_repo.txt
    fi
    #diff -rqNEZBi --strip-trailing-cr --ignore-trailing-space --exclude=.gitignore  --exclude=.git --exclude=$repo_name/.git --exclude=$repo_name/svn --exclude=description.md   $git_dir $svn_dir >> $project-comparison_report.txt
    echo " " >> $project-comparison_report.txt
    eval $cmd # print this out to the user too
    filenames_str=`$cmd`

    # remove lines that represent only one file, keep lines that have
    # files in both dirs, but are just different
    tmp1=`echo "$filenames_str" | sed -n '/ differ$/p'` 

    # grab just the first filename for the lines of output
    tmp2=`echo "$tmp1" | awk '{ print $2 }'`

    # convert newlines sep to space
    fs=$(echo "$tmp2") 

    # convert string to array
    fa=($fs) 

    for file in "${fa[@]}"
    do
        # drop first directory in path to get relative filename
        rel=`echo $file | sed "s#${git_dir}/##"`

        # determine the type of file
        file_type=`file -i $file | awk '{print $2}' | awk -F"/" '{print $1}'`

        # if it's a text file send it to meld
        if [ $file_type == "text" ]
        then
            # throw out error messages with &> /dev/null
            meld $git_dir/$rel $svn_dir/$rel &> /dev/null
        fi 
    done

    results=("$repo_name, $cmd")

    cd /workspace/libs/

    #echo "$results" 


    done < "$1"
}


function main (){
cd /workspace/libs

echo "what gitlab group are you comparing from?"
read project

    echo "What repo type would you like to compare?"
    echo "no branches: nb , has branches: hb, all repo: ar"
    read Compare_type
    

    #SELECTING MIGRATION TYPE
    if [ $Compare_type = 'nb' ]; then
        echo "Branchless repositories will be migrated now. "
        repo_list="no_branches.csv"
    else
        if [ $Compare_type = 'hb' ]; then
            echo "Repositories with branches will be migrated now. "
            repo_list="has_branches.csv"
        else
            if [ $Compare_type = 'ar' ]; then
                echo "All repositroeis will be migrated now"
                repo_list="all_repos.csv"
            else
                echo "Input not recognized."
                echo "Enter a specific csv file that you would like to migrate. example.csv || non_standard_repo.csv || failed_repo.csv"
                read repo_list
                echo "$repo_list was entered."
            fi
        fi
    fi

    #SELECTING MIGRATION TYPE
    echo "What type of comparision are you doing?"  
    echo "Full (export & compare): f | export only: e | comparison only: c"
    read Compare_type

    #Selecting clone type
    if [ $Compare_type = 'f' ]; then
    clone $repo_list $project
    compare $repo_list $project
    else
        if [ $Compare_type = 'e' ]; then
            clone $repo_list $project
        else
            if [ $Compare_type = 'c' ]; then
                compare $repo_list $project
            else
                echo "Input not recognized."
            fi
        fi
    fi

}

main


