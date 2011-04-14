#!/bin/bash
# created by liuggio @ tangent on Wed 30 Mar 2011
# load config
MY_DIR=`dirname $0`
source $MY_DIR/config.conf
source $MY_DIR/parameterFunctions.sh
if [ -z "$CONFIG_LOADED" ]; then
    echo "error on loading file";
    exit
fi

# default
SOURCE_HOST=$TEST_HOST
SOURCE_DATABASE=$TEST_DATABASE
SOURCE_USERNAME=$TEST_USERNAME
SOURCE_PASSWORD=$TEST_PASSWORD

DEST_HOST=$DEV_HOST
DEST_DATABASE=$DEV_DATABASE
DEST_USERNAME=$DEV_USERNAME
DEST_PASSWORD=$DEV_PASSWORD

# first generate a file with all the tables
# second clean that files removing the tables that are in the ignore Pattern File
# create or clean the file

# function that print the help
needHelp() {
	echo "usage:"
    echo "      --help or -h";
    echo ""
	echo "      $0 copy:structure [from [to]]";
    echo "        eg. copy:structure test dev";
    echo ""
	echo "      $0 copy:data";
    echo "        eg. copy:data test dev";
    echo ""
	echo "      $0 show:tables [from]";
    echo "        eg. show:tables test";
    echo ""
	echo "      $0 count:tables [from]";
    echo "        eg. count:tables test";
    echo ""
    echo "      $0 gzip:data [from]";
    echo "        eg. gzip:data live";
    echo ""
    echo "      $0 gzip:structure [from]";
    echo "        eg. gzip:structure live";
    echo ""
    echo "options"
    echo "       --exclude-from=\"FILE\""
    echo "       -e=\"FILE\""
    echo ""
    echo "       --include-from=\"FILE\""
    echo "       -i=\"FILE\""
    echo ""

}

importTables() {
    COUNTER=0;
    if [ "$CREATE_IMPORT_TABLES_FILE" -eq "1" ]; then
        echo "Populate List Tables ..."; 
        echo -n "{ "
        echo -n "" > $IMPORT_TABLES_FILE;
        # populate the file with all the tables
        echo show tables | mysql --host=$SOURCE_HOST  --user=$SOURCE_USERNAME --password=$SOURCE_PASSWORD --database=$SOURCE_DATABASE | while read Table
        do
            COUNTER=`expr $COUNTER + 1`;
            if [ "$COUNTER" -ne "1" ]; then
                echo -n "$COUNTER ";
                echo "$Table" >> $IMPORT_TABLES_FILE
            fi
        done
        echo ""
        echo -n "}"
        echo "the database has `cat $IMPORT_TABLES_FILE | wc -l` tables";
    fi
}

showTables() {
    importTables;
    cat $IMPORT_TABLES_FILE;
}

countTables() {
    importTables;   
}

removeFirstLine() {
    #removing the first line
    sed '1d' -i $IMPORT_TABLES_FILE
}

ignoreTables() {
    # removing the tables to ignore
    if [  "$USE_IGNORE_TABLES_FILE" -eq "1" ]; then
        echo "Using ignoring file $IGNORE_TABLES_FILE with `cat $IGNORE_TABLES_FILE| wc -l` lines";
        
        cat $IGNORE_TABLES_FILE | while read line
        do
            if [ ${#line} -gt 1 ]; then
                echo "Ignoring tables that match with";
                echo -n "$line "
                SED="sed '/^$line/d' -i $IMPORT_TABLES_FILE";
                eval $SED
            fi
        done
    fi
}
 
createCommandCopyTableFromSourceToDest() {
    tableName=$1;
    if [ -z "$1" ]; then
        return 1;
    else
        echo "mysqldump --host=$SOURCE_HOST --user=$SOURCE_USERNAME --password=$SOURCE_PASSWORD --opt $SOURCE_DATABASE $tableName  | mysql -h $DEST_HOST -u$DEST_USERNAME --password=$DEST_PASSWORD --database=$DEST_DATABASE";
        return 0;
    fi
}

createCommandCopyTableStructureFromSourceToDest() {
    tableName=$1;
    if [ -z "$1" ]; then
        return 1;
    else
        echo "mysqldump --host=$SOURCE_HOST --user=$SOURCE_USERNAME --password=$SOURCE_PASSWORD --no-data --opt $SOURCE_DATABASE $tableName  | mysql -h $DEST_HOST -u$DEST_USERNAME --password=$DEST_PASSWORD --database=$DEST_DATABASE";
        return 0;
    fi
}

createCommandGzipTableStructure() {
    tableName=$1;
    if [ -z "$1" ]; then
        return 1;
    else
        echo "mysqldump --host=$SOURCE_HOST --user=$SOURCE_USERNAME --password=$SOURCE_PASSWORD --no-data --opt $SOURCE_DATABASE $tableName  | gzip -c > $BACKUP_DIR/$tableName.gz ";
        return 0;
    fi
}

createCommandGzipTableData() {
    tableName=$1;
    if [ -z "$1" ]; then
        return 1;
    else
        echo "mysqldump --host=$SOURCE_HOST --user=$SOURCE_USERNAME --password=$SOURCE_PASSWORD --opt $SOURCE_DATABASE $tableName  | gzip -c > $BACKUP_DIR/$tableName.gz ";
        return 0;
    fi
}

# $1 contain the function to call
executeDump() {
    # executing mysqldump
  
    START=$(date +%s)
    ERRORCOUNTER=0
    if [ -z "$1" ]; then
        return 1;
    else
        echo "using $IMPORT_TABLES_FILE"
        cat $IMPORT_TABLES_FILE | while read tableName
        do    
            COUNTER=`expr $COUNTER + 1`;
            echo "============[$COUNTER]================================";
            echo "executing: {$1} [$tableName]";

            COMMAND=$(eval "$1 $tableName");
            echo $COMMAND | sed -e 's/password=[^ ]*/password=****/g';
            echo "{"
            STARTtmp=$(date +%s)
            #executing
            eval $COMMAND
            #fail?
            if [ "$?" -ne "0" ]; then
                echo "-fail $tableName"
                ERRORCOUNTER=`expr $ERRORCOUNTER + 1`;
            else
                echo "+success $tableName"
                SUCCESSCOUNTER=`expr $SUCCESSCOUNTER + 1`;
            fi         
             
            ENDtmp=$(date +%s)
            DIFFtmp=$(( $ENDtmp - $STARTtmp ))
            
            echo "$DIFFtmp sec } total Success:[$SUCCESSCOUNTER], Error:[$ERRORCOUNTER]";
        done
    fi
    END=$(date +%s)
    DIFF=$(( $END - $START ))
    echo "finished, consumed:[$DIFF] seconds";
}


 

copyStructure() {
    importTables
    removeFirstLine
    ignoreTables   
    executeDump createCommandCopyTableStructureFromSourceToDest
}
     
copyData() {
   importTables
   removeFirstLine
   ignoreTables
   executeDump createCommandCopyTableFromSourceToDest
}
 
    
gzipData() {
    importTables
    removeFirstLine
    ignoreTables
    
    BACKUP_DIR=$BACKUP_DIR/`date +"%b-%d-%y_%H-%m-%s"`
    echo "backup into $BACKUP_DIR"
 
    mkdir $BACKUP_DIR && executeDump createCommandGzipTableData
}

gzipStructure() {
    importTables
    removeFirstLine
    ignoreTables
    
    BACKUP_DIR=$BACKUP_DIR/`date +"%b-%d-%y_%H-%m-%s"`
    echo "backup into $BACKUP_DIR"
    mkdir $BACKUP_DIR && executeDump createCommandGzipTableStructure
}



#usage
# parameter --exclude-from=FILE
#           --include-from=FILE
# only with gzip:...
#           --backup-folder=directory
#       
#


handleParameter $@

if [ -z "$functionAction" ]; then
    echo "error on parameters"
    needHelp
    exit 1
fi

setSource $fromEnv
setDest $toEnv

printVars

echo "executing $functionAction"
eval $functionAction
echo "bye"
exit 0;

                                                         
                                                           
                                                           
                                                            
