#!/bin/bash

if [ "$#" -ne 4 ] ; then
   echo "Script requires 3 arguments to execute:"
   echo -e "\t-path to rpm spec file"
   echo -e "\t-rpm version for POM"
   echo -e "\t-rhel6 rpm name"
   echo -e "\t-rhel7 rpm name"
   exit 1
else
   spec_path=$1
   rpm_version=$2
   rhel6_rpm_name=$3
   rhel7_rpm_name=$4
fi

set -x
# Set package name and version taken from integration pom into rpm spec file
perl -pi.bak -e "s#\<rpm.name\>#${rhel6_rpm_name}#" SPEC/${spec_path}
perl -pi.bak -e "s#\<rpm.version\>#${rpm_version}#" SPEC/${spec_path}

# Build rhel6 rpm
rpmbuild --define "_topdir %(pwd)/" --define "_builddir %{_topdir}" --define "_rpmdir %{_topdir}/RPM" \
--define "_specdir %{_topdir}/SPEC" --define '_rpmfilename %%{NAME}-%%{VERSION}.%%{ARCH}.rpm' \
--define "_sourcedir %{_topdir}/SOURCES" --define "_localstatedir /var" --define "dist .el6" --define "rhel 6" -bb SPEC/${spec_path}

# Set rpm name to rhel7 rpm name in spec file
perl -pi.bak -e "s#${rhel6_rpm_name}#${rhel7_rpm_name}#" SPEC/${spec_path}

# Use mock to build rhel7 rpm
mock -r epel-7-x86_64 --resultdir=./RPM --arch=x86_64 --buildsrpm --spec=./SPEC/${spec_path} --sources=./SOURCES \
--rpmbuild-opts="--define '_localstatedir /var' --define 'dist .el7' --define 'rhel 7' -bb"

mock -r epel-7-x86_64 --resultdir=./RPM ./RPM/${rhel7_rpm_name}-${rpm_version}-1.src.rpm
