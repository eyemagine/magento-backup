#!/bin/sh

# Connection parameters
DBHOST=
DBUSER=
DBNAME=
DBPASS=
TBLPRF=

# Include DB logs option
SKIPLOGS=1

# Magento folder
MAGENTOROOT=./
LOCALXMLPATH=${MAGENTOROOT}app/etc/local.xml

# Output path
OUTPUTPATH=$MAGENTOROOT

# Content of file archive
DISTR="
app
downloader
errors
includes
js
lib
pkginfo
shell
skin
.htaccess
cron.php
cron.sh
get.php
index.php
install.php
mage
*.patch"

# Ignored table names
IGNOREDTABLES="
core_cache
core_cache_option
core_cache_tag
core_session
log_customer
log_quote
log_summary
log_summary_type
log_url
log_url_info
log_visitor
log_visitor_info
log_visitor_online
enterprise_logging_event
enterprise_logging_event_changes
index_event
index_process_event
report_event
report_viewed_product_index
dataflow_batch_export
dataflow_batch_import"

# Get random file name - some secret link for downloading from magento instance :)
MD5=`echo \`date\` $RANDOM | md5sum | cut -d ' ' -f 1`
DATETIME=`date -u +"%Y%m%d%H%M"`
CODEFILENAME="$OUTPUTPATH$MD5.$DATETIME.tar.gz"
DBFILENAME="$OUTPUTPATH$MD5.$DATETIME.sql.gz"

# Create code dump
DISTRNAMES=
for ARCHPART in $DISTR; do
    if [ -r "$MAGENTOROOT$ARCHPART" ]; then
        DISTRNAMES="$DISTRNAMES $MAGENTOROOT$ARCHPART"
    fi
done
if [ -n "$DISTRNAMES" ]; then
    echo nice -n 15 tar -czhf $CODEFILENAME $DISTRNAMES
 #   nice -n 15 tar -czhf $CODEFILENAME $DISTRNAMES
fi

# Get mysql credentials from local.xml
getLocalValue() {
    PARAMVALUE=`sed -n "/<resources>/,/<\/resources>/p" $LOCALXMLPATH | sed -n -e "s/.*<$PARAMNAME><!\[CDATA\[\(.*\)\]\]><\/$PARAMNAME>.*/\1/p" | head -n 1`
}

if [ -z "$DBHOST" ]; then
    PARAMNAME=host
    getLocalValue
    DBHOST=$PARAMVALUE
fi
if [ -z "$DBUSER" ]; then
    PARAMNAME=username
    getLocalValue
    DBUSER=$PARAMVALUE
fi
if [ -z "$DBPASS" ]; then
    PARAMNAME=password
    getLocalValue
    DBPASS=$PARAMVALUE
fi
if [ -z "$DBNAME" ]; then
    PARAMNAME=dbname
    getLocalValue
    DBNAME=$PARAMVALUE
fi
if [ -z "$TBLPRF" ]; then
    PARAMNAME=table_prefix
    getLocalValue
    TBLPRF=$PARAMVALUE
fi

if [ -z "$DBHOST" -o -z "$DBUSER" -o -z "$DBNAME" ]; then
    echo "Skip DB dumping due lack of parameters host=$DBHOST; username=$DBUSER; dbname=$DBNAME;";
    exit
fi
CONNECTIONPARAMS=" -u$DBUSER -h$DBHOST -p'$DBPASS' $DBNAME --single-transaction --opt --skip-lock-tables"

# Create DB dump
IGN_SCH=
IGN_IGN=
if [ -n "$SKIPLOGS" ] ; then
    for TABLENAME in $IGNOREDTABLES; do
        IGN_SCH="$IGN_SCH $TBLPRF$TABLENAME"
        IGN_IGN="$IGN_IGN --ignore-table='$DBNAME'.'$TBLPRF$TABLENAME'"
    done
fi

if [ -z "$IGN_IGN" ]; then
    CODEDUMPCMD="nice -n 15 mysqldump $CONNECTIONPARAMS"
else
    CODEDUMPCMD="( nice -n 15 mysqldump $CONNECTIONPARAMS $IGN_IGN ; nice -n 15 mysqldump --no-data $CONNECTIONPARAMS $IGN_SCH )"
fi

CODEDUMPCMD="$CODEDUMPCMD | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > $DBFILENAME"
echo $CODEDUMPCMD
eval "$CODEDUMPCMD"
