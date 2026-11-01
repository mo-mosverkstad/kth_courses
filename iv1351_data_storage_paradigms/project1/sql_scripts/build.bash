sudo -u postgres psql -d course_database -f clean-postgresql.sql
sudo -u postgres psql -d course_database -f logical-physical-postgresql.sql
sudo -u postgres psql -d course_database -f trigger-postgresql.sql
sudo -u postgres psql -d course_database -f db-insertion-postgresql.sql