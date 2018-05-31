#!/bin/sh
#
# Generate cache of patch data for consumption by Puppet custom facts.
#

PATH=/usr/bin:/usr/sbin:/bin:/usr/local/bin

case $(/usr/local/bin/facter osfamily) in
  RedHat)
    PKGS=$(yum -q check-update | awk '{print $1}')
    SECPKGS=$(yum -q --security check-update | awk '{print $1}')
  ;;
  Debian)
    PKGS=$(apt-get upgrade -s | awk '$1 == "Inst" {print $2}')
    SECPKGS=$(apt-get upgrade -s | awk '$1 == "Inst && /security/" {print $2}')
  ;;
  *)
    exit 1
  ;;
esac

FACTDIR='/opt/puppetlabs/facter/facts.d'
FACTFILE="${FACTDIR}//os_patching.yaml"

if [ ! -d "${FACTDIR}" ]
then
  /usr/bin/logger -p error -t os_patching_fact_generation.sh "Can't find ${FACTDIR}, exiting"
  exit 1
fi

echo "---" > ${FACTFILE}
if [ "$?" -gt 1 ]
then
  /usr/bin/logger -p error -t os_patching_fact_generation.sh "Can't write to ${FACTFILE}, exiting"
  exit 1
fi

echo "os_patching:" >> ${FACTFILE} || exit 1

COUNT=0
echo "  package_updates:" >> ${FACTFILE} || exit 1
for UPDATE in $PKGS
do
  echo "   - '$UPDATE'" >> ${FACTFILE} || exit 1
  COUNT=$((COUNT + 1))
done

SECCOUNT=0
echo "  security_package_updates:" >> ${FACTFILE} || exit 1
for UPDATE in $SECPKGS
do
  echo "   - '$UPDATE'" >> ${FACTFILE} || exit 1
  SECCOUNT=$((SECCOUNT + 1))
done

echo "  package_update_count: $COUNT" >> ${FACTFILE} || exit 1
echo "  security_package_update_count: $SECCOUNT" >> ${FACTFILE} || exit 1

/usr/bin/logger -p info -t os_patching_fact_generation.sh "patch data fact refreshed"

exit 0
