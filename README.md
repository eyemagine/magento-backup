magento-backup
==============

This script will create a file and database dump of a Magento application.

###Features

 * Automatically enters database credentials
 * Ignores contents of log tables
 * Obfuscates customer information

###Usage

    cd /path/to/magento/
    wget --no-check-certificate https://raw.githubusercontent.com/eyemagine/magento-backup/master/backup.sh
    chmod +x backup.sh
    ./backup.sh

###Credits

This script was originally developed by the Magento Core team.
