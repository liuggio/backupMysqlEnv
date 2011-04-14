#!/bin/bash
echo -n "loading parameters.conf ... "
handleParameter() {

    TEMP=`getopt -o he::i:: --long help,exclude-from::,include-from:: \
         -n 'example.bash' -- "$@"`

    if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
    COUNTER=0
    # Note the quotes around `$TEMP': they are essential!
    eval set -- "$TEMP"
    # Options
    while true ; do
            case "$1" in
                    -h|--help) needHelp; exit 0; shift ;;
                    -e|--exclude-from)
                            case "$2" in
                                    "") echo "Error '--exclude-from' must contain a file eg. --exclude-from='file.txt'"; needHelp; exit 1 ;;
                                    *)  echo "Excluding list from \`$2\` " ;IGNORE_TABLES_FILE="$2";USE_IGNORE_TABLES_FILE="1"; shift 2 ;;
                            esac ;;
                    -i|--include-from)
                            case "$2" in
                                    "") echo "Error '--include-from' must contain a file eg. --include-from='file.txt'"; needHelp; exit 1 ;;
                                    *)  echo "Importing list from \`$2\` " ;IMPORT_TABLES_FILE="$2";CREATE_IMPORT_TABLES_FILE="1"; shift 2 ;;
                            esac ;;
                    --) shift ; break ;;
                    *) echo "Internal error!" ; exit 1 ;;
            esac
    done
    # Parameters
    for arg do

        COUNTER=`expr $COUNTER + 1`;     
        if [ $COUNTER -eq "1" ]; then
            if [ -z "$arg" ]; then
                functionAction = "needHelp"
                needThird="1"
                
            elif [ $arg = "copy:structure" ]; then
                functionAction="copyStructure"
                needThird="1"
                            
            elif [ $arg = "copy:data" ]; then
                functionAction="copyData"
                NEED_THIRD=1
               
            elif [ $arg = "show:tables" ]; then
                functionAction="showTables"
                
            elif [ $arg = "count:tables" ]; then
                functionAction="countTables"
                
            elif [ $arg = "gzip:data" ]; then
                functionAction="gzipData"
              
            elif [ $arg = "gzip:structure" ]; then
                functionAction="gzipStructure"
                
            else
                functionAction="needHelp"
            fi

        elif [ $COUNTER -eq "2" ]; then

            if [ $arg = "dev" ] || [ $arg = "test" ]  || [ $arg = "live" ]; then
                fromEnv="$arg"
            else
                echo "source must be dev or test or live"
                needHelp
                exit 1
            fi
                
        elif [ $COUNTER -eq "3" ] && [ "$NEED_THIRD" = "1" ]; then

            if [ "$arg" != "$fromEnv" ]; then
                if [ $arg = "dev" ] || [ $arg = "test" ]; then        
                    toEnv="$arg"
                else
                    echo "destination must be dev or test"
                    needHelp
                    exit 1
                fi            
            else
                echo "destination must be diffrent from the source $fromEnv"
                functionAction="needHelp"
                exit 1
            fi
        fi
       

    done
}

# $1 contain the env
setSource() {
 
    if [ "$1" = "live" ]; then
        SOURCE_HOST=$LIVE_HOST
        SOURCE_DATABASE=$LIVE_DATABASE
        SOURCE_USERNAME=$LIVE_USERNAME
        SOURCE_PASSWORD=$LIVE_PASSWORD
        
    elif [ "$1" = "test" ]; then
        SOURCE_HOST=$TEST_HOST
        SOURCE_DATABASE=$TEST_DATABASE
        SOURCE_USERNAME=$TEST_USERNAME
        SOURCE_PASSWORD=$TEST_PASSWORD
        
    elif [ "$1" = "dev" ]; then    
        SOURCE_HOST=$DEV_HOST
        SOURCE_DATABASE=$DEV_DATABASE
        SOURCE_USERNAME=$DEV_USERNAME
        SOURCE_PASSWORD=$DEV_PASSWORD
    fi
}

# $1 contain the env
setDest() {
    echo "destination setting [$1]"
    if [ "$1" = "test" ]; then
        DEST_HOST=$TEST_HOST
        DEST_DATABASE=$TEST_DATABASE
        DEST_USERNAME=$TEST_USERNAME
        DEST_PASSWORD=$TEST_PASSWORD
     
    elif [ "$1" = "dev" ]; then    
        DEST_HOST=$DEV_HOST
        DEST_DATABASE=$DEV_DATABASE
        DEST_USERNAME=$DEV_USERNAME
        DEST_PASSWORD=$DEV_PASSWORD
    fi
}

printVars() {
    
    echo "using source: $fromEnv[$SOURCE_USERNAME@$SOURCE_HOST/$SOURCE_DATABASE]"
    if [ "$NEED_THIRD" = "1" ]; then
        echo "using destination: $toEnv[$DEST_USERNAME@$DEST_HOST/$DEST_DATABASE]"
    fi
    echo "using as import file: $IMPORT_TABLES_FILE"
     
    
}
echo " loaded!"
PARAMS_LOADED=1
