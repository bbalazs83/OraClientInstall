#Oracle Client 12.1.0.2.160419 + NetAdm Install Script
# Autor: Balazs Berki
# LastChangedDate: 2016-06-22

#!/bin/bash
#Variable Declaration

if [ "$#" -eq 1 ]; then
  echo "Oracle Base will be set to" $1
  ORACLE_BASE=$1
else
  ORACLE_BASE=/u00/oracle/orabase
fi

UNIX_GROUP_NAME=dba
patch_nr=22291127
ora_home_ver=Ora12102_160419
scriptpath=`pwd`
MySETUPFILE=$scriptpath/client/runInstaller
MyRESPONSEFILE=$scriptpath/custom_install_client.rsp
ORACLE_HOME=$ORACLE_BASE/$ora_home_ver
ORACLE_HOME_NAME=12102_160419_x64_client
INVENTORY_LOCATION=$ORACLE_BASE/Inventory

makelog=$ORACLE_HOME/install/make.log

ORANET_SRC=$scriptpath/NetAdm
ORANET_TRGT=$ORACLE_BASE


#Functions
add_env_var () {
  if ! grep "$1" ~/.bashrc &> /dev/null; then
    echo $1 >> ~/.bashrc
  fi
}

#Main
$MySETUPFILE -ignorePrereq -ignoreSysPrereqs -waitforcompletion -nowait -silent -responseFile $MyRESPONSEFILE ORACLE_BASE=$ORACLE_BASE ORACLE_HOME=$ORACLE_HOME ORACLE_HOME_NAME=$ORACLE_HOME_NAME INVENTORY_LOCATION=$INVENTORY_LOCATION UNIX_GROUP_NAME=$UNIX_GROUP_NAME

if [ $? -eq 0 ]; then
  echo "Client Installed"
  if grep -i fatal $makelog; then
    echo "Make failed, probably libraries will be missing, aborting install. More info in "$makelog
    exit 1
  fi
else
  exit $?
fi

rm $ORACLE_HOME/oraInst.loc
echo "inventory_loc=$INVENTORY_LOCATION" >$ORACLE_HOME/oraInst.loc
echo "inst_group=$UNIX_GROUP_NAME" >>$ORACLE_HOME/oraInst.loc

echo "Copying Oracle NetAdm ..."
cp -r $ORANET_SRC $ORACLE_BASE

if [ $? -eq 0 ]; then
  echo "Success!"
else
  exit $?
fi

add_env_var "export ORACLE_BASE=$ORACLE_BASE"
add_env_var "export ORACLE_HOME=$ORACLE_HOME"
add_env_var "export LD_LIBRARY_PATH=$ORACLE_HOME/lib"
add_env_var "export PATH=\$PATH:$ORACLE_HOME/bin"
add_env_var "export TNS_ADMIN=$ORACLE_BASE/NetAdm"

echo "Patching Client"
#copy OPatch
mv $ORACLE_HOME/OPatch $ORACLE_HOME/OPatch_old
cp -R OPatch $ORACLE_HOME

#install PSU April:
cd $scriptpath/$patch_nr
$ORACLE_HOME/OPatch/opatch apply -silent -ocmrf $scriptpath/ocm.rsp

if [ $? -eq 0 ]; then
  echo "Success!"
else
  exit $?
fi

echo "Install finished, please relog or execute: . ~/.bashrc"
[ -f /etc/oraInst.loc ] && echo "Oracle Inventory is already installed. Nothing more to do." || echo "Oracle inventory not found. Please execute $INVENTORY_LOCATION/orainstRoot.sh as root user"

