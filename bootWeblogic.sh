#####################################################################################################################
# Written by Avirup Das                                                                                            #
# Version v1.3                                                                                                      #
# Dated : 10 Febraury 2018                                                                                          #
#                                                                                                                   #
# Purpose : Complete automation of Oracle Weblogic start up                                                         #
#                       via shell script                                                                            #
#           This reduces time of accessing console from web browser                                                 #
#                       and removes the manual process of starting each server                                      #
#                                                                                                                   #
# Environment : RHEL 6.8, Weblogic 12.1.3 {domain(1), admin server(1), nodemanager(1), managed server(2)}           #
#                                                                                                                   #
# Weblogic installation path :  /app2/oracle                                                                        #
# Name of domain : base_domain                                                                                      #
# Name of Managed servers : ManagedServer_1, ManagedServer_2                                                        #
#####################################################################################################################

var_weblogic_installation_path="/app2/oracle"
var_admin_url="http://IP:PORT"
var_base_domain="base_domain"
var_managedserver_1="ManagedServer_1"
var_managedserver_2="ManagedServer_2"
var_wait_seconds=5

RUNNING="<Server state changed to RUNNING.>"
RESUME=" is being brought up in administration state due to failed deployments."

echo "Starting NODEMANAGER : "`date +%T`
`nohup sh $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/startNodeManager.sh > $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/nodemanager.out &`
mv $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/adminserver.out $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/adminserver.out.`date +%F`
echo "Starting ADMINSERVER : "`date +%T`
`nohup sh $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/startWebLogic.sh > $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/adminserver.out &`
a=0
while [ $a -lt 1 ]
do
        sleep $var_wait_seconds
        count=`cat $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/adminserver.out | grep -c "$RUNNING"`
        echo $count
        if [ $count -ge 1 ]
        then
                a=`expr $a + 1`
                echo "ADMINSERVER is running : "`date +%T`
                echo "Starting $var_managedserver_1 : "`date +%T`
                mv $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_1/logs/$var_managedserver_1.out $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_1/logs/$var_managedserver_1.out.`date +%F`
                nohup sh $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/startManagedWebLogic.sh $var_managedserver_1 $var_admin_url > $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_1/logs/$var_managedserver_1.out &
                while [ $a -lt 2 ]
                do
                        sleep $var_wait_seconds
                        countManaged=`cat $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_1/logs/$var_managedserver_1.log | grep -c "$RUNNING"`
						resumeState=`cat $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_1/logs/$var_managedserver_1.log | grep -c "$RESUME"`
						if [ $resumeState -ge 1 ]
						then
							countManaged=1
							echo "$var_managedserver_1 was put into resume state due to some error"
						fi
						if [ $countManaged -ge 1 ]
                        then
                                a=`expr $a + 1`
                                echo "$var_managedserver_1 is running : "`date +%T`
                                echo "Starting $var_managedserver_2 : "`date +%T`
                                mv $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_2/logs/$var_managedserver_2.out $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_2/logs/$var_managedserver_2.out.`date +%F`
                                nohup sh $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/bin/startManagedWebLogic.sh $var_managedserver_2 $var_admin_url > $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_2/logs/$var_managedserver_2.out &
                                while [ $a -lt 3 ]
                                do
                                        sleep $var_wait_seconds
                                        countManaged=`cat $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_2/logs/$var_managedserver_2.log | grep -c "$RUNNING"`
										resumeState=`cat $var_weblogic_installation_path/Middleware/Oracle_Home/user_projects/domains/$var_base_domain/servers/$var_managedserver_2/logs/$var_managedserver_2.log | grep -c "$RESUME"`
										if [ $resumeState -ge 1 ]
										then
											countManaged=1
											echo "$var_managedserver_2 was put into resume state due to some error"
										fi
                                        if [ $countManaged -ge 1 ]
                                        then
                                                a=`expr $a + 1`
                                                echo "$var_managedserver_2 is running : "`date +%T`
                                        else
                                                echo "Waiting on $var_managedserver_2 : "`date +%T`
                                        fi
                                done
                        else
                                echo "Waiting on ManagedServer_1 : "`date +%T`
                        fi
                done
        else
                echo "Waiting on ADMINSERVER : "`date +%T`
        fi
done


