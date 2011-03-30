#!/bin/bash
# created by liuggio @ tangent on Wed 30 Mar 2011
# load config
MY_DIR=`dirname $0`
source $MY_DIR/config.conf
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
	echo "      $0 copy:structure [from [to]]";
    echo "        eg. copy:structure test dev";
	echo "      $0 copy:data";
    echo "        eg. copy:data test dev";
	echo "      $0 show:tables [from]";
    echo "        eg. show:tables test";
	echo "      $0 count:tables [from]";
    echo "        eg. count:tables test";
    echo "      $0 gzip:data [from]";
    echo "        eg. gzip:data live";
    echo "      $0 gzip:structure [from]";
    echo "        eg. gzip:structure live";               
}

importTables() {
    COUNTER=0;
    echo "import $CREATE_IMPORT_TABLES_FILE";
    if [ "$CREATE_IMPORT_TABLES_FILE" -eq "1" ]; then
        echo "Populate List Tables ..."; 
        echo "{"
        echo "" > $IMPORT_TABLES_FILE;
        # populate the file with all the tables
        echo show tables | mysql --host=$SOURCE_HOST  --user=$SOURCE_USERNAME --password=$SOURCE_PASSWORD --database=$SOURCE_DATABASE | while read Table
        do
            COUNTER=`expr $COUNTER + 1`;
            if [ "$COUNTER" -ne "1" ]; then
                echo -n "$COUNTER ";
                echo "$Table" >> $IMPORT_TABLES_FILE
            fi
        done
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
    cat $IMPORT_TABLES_FILE | wc -l;   
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
    COUNTER=0;
    ERRORCOUNTER=0;
    SUCCESSCOUNTER=0;
    START=$(date +%s)

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
                ERRORCOUNTER=`expr $ERRORCOUNTER + 1`;
            else
                SUCCESSCOUNTER=`expr $SUCCESSCOUNTER + 1`;
            fi         
             
            ENDtmp=$(date +%s)
            DIFFtmp=$(( $ENDtmp - $STARTtmp ))
            echo "consumed:[$DIFFtmp] seconds"; 
            echo "}"
        done
    fi
    END=$(date +%s)
    DIFF=$(( $END - $START ))

    echo "ERRORS: [$ERRORCOUNTER], OK: [$SUCCESSCOUNTER]";
    echo "consumed:[$DIFF] seconds";
}


if [ -z "$2" ]; then
    echo "using TEST as Source";
    
elif [ $2 = "live" ]; then
    SOURCE_HOST=$LIVE_HOST
    SOURCE_DATABASE=$LIVE_DATABASE
    SOURCE_USERNAME=$LIVE_USERNAME
    SOURCE_PASSWORD=$LIVE_PASSWORD
    
elif [ $2 = "test" ]; then
    SOURCE_HOST=$TEST_HOST
    SOURCE_DATABASE=$TEST_DATABASE
    SOURCE_USERNAME=$TEST_USERNAME
    SOURCE_PASSWORD=$TEST_PASSWORD
    
elif [ $2 = "dev" ]; then    
    SOURCE_HOST=$DEV_HOST
    SOURCE_DATABASE=$DEV_DATABASE
    SOURCE_USERNAME=$DEV_USERNAME
    SOURCE_PASSWORD=$DEV_PASSWORD
    
else
    echo "error use live|test|dev"
fi


if [ -z "$3" ]; then
    echo "";
    
elif [ $3 = "live" ]; then
    echo "error is not possible to use LIVE as destination";
    
elif [ $3 = "test" ]; then
    DEST_HOST=$TEST_HOST
    DEST_DATABASE=$TEST_DATABASE
    DEST_USERNAME=$TEST_USERNAME
    DEST_PASSWORD=$TEST_PASSWORD
 
elif [ $3 = "dev" ]; then    
    DEST_HOST=$DEV_HOST
    DEST_DATABASE=$DEV_DATABASE
    DEST_USERNAME=$DEV_USERNAME
    DEST_PASSWORD=$DEV_PASSWORD
    
fi



if [ -z "$1" ]; then
    needHelp
elif [ $1 = "copy:structure" ]; then
    echo "copy structure"
    importTables
    removeFirstLine
    ignoreTables   
    executeDump createCommandCopyTableStructureFromSourceToDest
                
elif [ $1 = "copy:data" ]; then
   echo "copy data"
   importTables
   removeFirstLine
   ignoreTables
   executeDump createCommandCopyTableFromSourceToDest
   
elif [ $1 = "show:tables" ]; then
    echo "showTables";
    showTables

elif [ $1 = "count:tables" ]; then
    echo "countTables";
    countTables
    
elif [ $1 = "gzip:data" ]; then
    echo "gzipping data";

    importTables
    removeFirstLine
    ignoreTables
    
    BACKUP_DIR=$BACKUP_DIR/`date +"%b-%d-%y_%H-%m-%s"`
    echo "backup into $BACKUP_DIR"
 
    mkdir $BACKUP_DIR && executeDump createCommandGzipTableData
    
elif [ $1 = "gzip:structure" ]; then
    echo "gzipping structure";

    importTables
    removeFirstLine
    ignoreTables
    
    BACKUP_DIR=$BACKUP_DIR/`date +"%b-%d-%y_%H-%m-%s"`
    echo "backup into $BACKUP_DIR"
 
    mkdir $BACKUP_DIR && executeDump createCommandGzipTableStructure
    
else
    needHelp
fi
                   
       
  
                                                         
                                                           
                                                           
                                                            
