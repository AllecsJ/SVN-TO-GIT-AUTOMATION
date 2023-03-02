# SVN-TO-GIT-AUTOMATION
AUTOMATED THE SVN TO GIT MIGRATION FOR JMMB


Run ./Migrate.sh to migrate the svn repository to git.

The prompt will ask for the gitlab group, migration type (which chooses the file name). 

Run ./compare.sh to download the svn repo and git repo and comapres them both and returns a result in a file
The prompt will ask for the gitlab group, migration type (which chooses the file name) and the comparison type (full, export only, compare only).

Run ./report to generate the report for the migrated files.
