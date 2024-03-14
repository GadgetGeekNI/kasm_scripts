# My Recommendation for the upgrade path would be...
# Turn off Autoscaling.
# Terminate All Agents & 1 WebApp.
# SSM session into the remaining WebApp.
# Stop all Kasm Services on that WebApp. - This is done with the command below
# Run each command individually.
# After the WebApp Upgrade command is done, log back into the UI and verify that;
# Custom Container configs are still there.
# SAML settings, Users, ETC are still there.
# Find the Autoscaling Userdata, update it to the newest build URL. 
# Enable 1 Autoscaling Config to create an agent. Let it come up, install the containers etc..
# Verify that the containers still work. - The Chrome container may look jank, this is because it's version 1.13 trying to run on 1.15 and there's some graphical issues there.
# After that, change the Terraform Workspace Var to the newest Kasm build URL.
# Apply the Terraform, this will rebuild the WebApps (and agents if applicable)
# Verify that it still works again. Container test of Pandion Desktop & Pandion Chrome at the very bare minimum. The Chrome container may look jank, this is because it's version 1.13 trying to run on 1.15 and there's some graphical issues there.
# In the Kasm Custom Workspaces Repo, Update the Base version from 1.13.0 to 1.15.0 here, do 1 at a time. Pandion Chrome first, then Pandion Desktop.. Then the others can be deployed en-masse.
# In the Kasm Workspace Registry Repo, Update the version compatibility from 1.13.0 to 1.15.0
# It can take an hour to pull down the latest images from here so you may want to go into an Agent via SSM and manually pull one down after it's been deployed.
# Run that container again, verify that it still works.

# General vars
KASM_RELEASE_URL="https://kasm-static-content.s3.amazonaws.com/kasm_release_1.15.0.06fdc8.tar.gz"
KASM_VERSION="1.15.0"
KASM_UTIL_LOCATION="/opt/kasm"

# DB Vars
DB_HOSTNAME="kasm.db_name.us-east-1.rds.amazonaws.com"
DB_BACKUP_LOCATION="$KASM_UTIL_LOCATION/backups"
DB_BACKUP_FILENAME="kasm_db_backup.tar"
DB_PASSWORD="12345"
DB_USER="kasmapp"
DB_NAME="kasm"

# WebApp Vars

REDIS_HOSTNAME="clustercfg.kasm-infdev-redis.name.use1.cache.amazonaws.com"

# Stop Kasm Services on this endpoint (This needs done on every Kasm Agent / WebApp pre-upgrade!)
sudo bash $KASM_UTIL_LOCATION/bin/stop

# Create a location for the DB Backup
sudo mkdir -p $DB_BACKUP_LOCATION

# I'm lazy..
cd /tmp

# Pull the latest Kasm installer
wget $KASM_RELEASE_URL -O kasm_workspaces.tar.gz

# TARFFUL THE WOOKIE LEADER
tar -xf kasm_workspaces.tar.gz

# Automated DB Backup
# sudo bash /tmp/kasm_release/bin/utils/db_backup \
# --backup-file $DB_BACKUP_LOCATION/$DB_BACKUP_FILENAME \
# --database-hostname $DB_HOSTNAME \
# --database-user $DB_USER \
# --database-name $DB_NAME \
# --path $KASM_UTIL_LOCATION/current

# Results in...
# pg_dump: error: server version: 13.8; pg_dump version: 12.18
# pg_dump: error: aborting because of server version mismatch

# Manual DB Backup (Can't use Kasm's own as it only supports Postgres 12 and not our 13.8 Aurora version)
sudo docker run -v $DB_BACKUP_LOCATION:/backup/ -e PGPASSWORD=$DB_PASSWORD --rm postgres:13-alpine pg_dump -b -C -h $DB_HOSTNAME -p '' -U $DB_USER -Ft $DB_NAME -f "/backup/$DB_BACKUP_FILENAME"

# Drop DB
sudo docker run -e PGPASSWORD=$DB_PASSWORD --rm postgres:13-alpine psql -h $DB_HOSTNAME -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS $DB_NAME;"
# Drop User (Doesn't work because the Master User is the Kasm User)
# sudo docker run -e PGPASSWORD=$DB_PASSWORD --rm postgres:13-alpine psql -h $DB_HOSTNAME -U $DB_USER -d $DB_NAME -c "DROP USER IF EXISTS $DB_USER;"

# DB Init - Prepare it for new version - We know that this works (This will prompt for a y/n, hit yes.)
sudo bash /tmp/kasm_release/install.sh \
--accept-eula \
--role init_remote_db \
--db-hostname $DB_HOSTNAME \
--db-password $DB_PASSWORD \
--database-user $DB_USER \
--database-name $DB_NAME \
--db-master-user $DB_USER \
--db-master-password $DB_PASSWORD

# # Restore DB - Pull our Backup back in - Not convinced this works - {Restore and update the database from the prior version} - Did not work
# sudo bash $KASM_UTIL_LOCATION/$KASM_VERSION/bin/utils/db_restore \
# --backup-file $DB_BACKUP_LOCATION/$DB_BACKUP_FILENAME \
# --database-hostname $DB_HOSTNAME \
# --path $KASM_UTIL_LOCATION/$KASM_VERSION \
# --database-master-user $DB_USER \
# --database-user $DB_USER \
# --database-name $DB_NAME \
# --database-master-password $DB_PASSWORD

# Drop DB
sudo docker run -e PGPASSWORD=$DB_PASSWORD --rm postgres:13-alpine psql -v ON_ERROR_STOP=on -h $DB_HOSTNAME -e -U $DB_USER -c "drop database if exists $DB_NAME;" postgres

# Create DB
sudo docker run -e PGPASSWORD=$DB_PASSWORD --rm postgres:13-alpine psql -v ON_ERROR_STOP=on -h $DB_HOSTNAME -e -U $DB_USER -c "create database $DB_NAME;" postgres

# Copy Backup to other location so it doesn't bork
sudo cp -r $DB_BACKUP_LOCATION/$DB_BACKUP_FILENAME $KASM_UTIL_LOCATION/current/conf/database/$DB_BACKUP_FILENAME

# Drop Schema
sudo docker run -e PGPASSWORD=$DB_PASSWORD --rm postgres:13-alpine psql -v ON_ERROR_STOP=on -h $DB_HOSTNAME -e -U $DB_USER -c "drop schema if exists public cascade;" $DB_NAME

# Create Schema
sudo docker run -e PGPASSWORD=$DB_PASSWORD --rm postgres:13-alpine psql -v ON_ERROR_STOP=on -h $DB_HOSTNAME -U $DB_USER -c "CREATE SCHEMA IF NOT EXISTS public;" $DB_NAME

# Restore from Backup
sudo docker run -v "$KASM_UTIL_LOCATION/current/conf/database/$DB_BACKUP_FILENAME:/restore/$DB_BACKUP_FILENAME" -e PGPASSWORD=$DB_PASSWORD --rm postgres:12-alpine pg_restore -h $DB_HOSTNAME -e -U $DB_USER -Ft -d $DB_NAME  "/restore/$DB_BACKUP_FILENAME"

# Upgrade DB - Upgrade the DB Schema
sudo bash $KASM_UTIL_LOCATION/$KASM_VERSION/bin/utils/db_upgrade --database-hostname $DB_HOSTNAME --path $KASM_UTIL_LOCATION/$KASM_VERSION

# Web App In Place Upgrade.

sudo bash /tmp/kasm_release/install.sh -S app -e -z default -q $DB_HOSTNAME -Q $DB_PASSWORD -o $REDIS_HOSTNAME -R ""
