* Utility for copy or move database between hosts and environment
==================


just populate properly the config.conf
and the ignore file (if you want)
and run 

    usage:
      ./backupMysqlEnv.sh copy:structure [from [to]]
        eg. copy:structure test dev
      ./backupMysqlEnv.sh copy:data
        eg. copy:data test dev
      ./backupMysqlEnv.sh show:tables [from]
        eg. show:tables test
      ./backupMysqlEnv.sh count:tables [from]
        eg. count:tables test
      ./backupMysqlEnv.sh gzip:data [from]
        eg. gzip:data live
      ./backupMysqlEnv.sh gzip:structure [from]
        eg. gzip:structure live