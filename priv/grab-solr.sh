#!/bin/bash
#
# Script to grab Solr and embed in priv dir.
#
# Usage:
#     ./grab-solr.sh

FROM_SRC=false
HTTP_VER="httpcomponents-client-4.2.2"
WAR_DIR=solr-war
WAR_FILE=webapps/solr.war

if [ $(basename $PWD) != "priv" ]
then
    cd priv
fi

while [ $# -gt 0 ]
do
    case $1 in
        from-src)
            FROM_SRC=true
            shift
            ;;
        *)
            echo Invalid argument $1
            exit 1
    esac
done

if $FROM_SRC; then
    dir=$PWD/solr
    src_dir=$PWD/lucene-solr
    example_dir=$src_dir/solr/example
    patch_dir=$PWD/solr-patches
    branch=branch_4x
else
    dir=$PWD/solr
    src_dir=$PWD/apache-solr-4.0.0
    example_dir=$src_dir/example
fi

apply_patches()
{
    if [ -e $patch_dir ]; then
        echo "applying patches in $patch_dir"
        for p in $patch_dir/*.patch; do
            patch -p1 < $p
        done
    fi
}

build_solr()
{
    pushd $src_dir
    apply_patches
    ant compile
    pushd solr
    mkdir test-framework/lib
    ant dist example
    popd
    popd
}

checkout_branch()
{
    branch=$1
    pushd $src_dir
    git checkout $branch
    popd
}

check_for_solr()
{
    test -e $dir
}

get_solr()
{
    if $FROM_SRC; then
        git clone git://github.com/apache/lucene-solr.git
    else
        wget http://apache.mesi.com.ar/lucene/solr/4.0.0/apache-solr-4.0.0.tgz
        tar zxvf apache-solr-4.0.0.tgz
    fi
}

explode_war()
{
    if [ ! -e $WAR_DIR ]; then
        mkdir $WAR_DIR
        cp $dir/$WAR_FILE $WAR_DIR
        pushd $WAR_DIR
        jar xvf solr.war
        rm -f solr.war
        popd
    fi
}

update_war()
{
    if jar tvf $dir/$WAR_FILE | grep 'httpclient.*4.1.*'; then
        pushd $WAR_DIR
        rm -f $dir/$WAR_FILE
        jar cvf $dir/$WAR_FILE *
        popd
    fi
}

get_apache_http()
{
    if [ ! -e $HTTP_VER ]; then
        wget http://www.apache.org/dist/httpcomponents/httpclient/binary/${HTTP_VER}-bin.tar.gz
        tar zxvf ${HTTP_VER}-bin.tar.gz
    fi
}

swap_http_client()
{
    get_apache_http
    if [ -e $WAR_DIR/WEB-INF/lib/httpclient-4.1*.jar ]; then
        rm -rf $WAR_DIR/WEB-INF/lib/httpclient*
        rm -rf $WAR_DIR/WEB-INF/lib/httpcore*
        cp $HTTP_VER/lib/httpclient-4*.jar $WAR_DIR/WEB-INF/lib
        cp $HTTP_VER/lib/httpcore-4*.jar $WAR_DIR/WEB-INF/lib
    fi
}

if check_for_solr
then
    echo "Solr already exists, exiting..."
    exit 0
fi

if [ ! -e $src_dir ]
then
    get_solr
fi

if $FROM_SRC; then
    checkout_branch $branch
    build_solr
fi

cp -vr $example_dir $dir
rm -rf $dir/{cloud-scripts,example-DIH,exampledocs,multicore,logs,solr,README.txt}
cp -v solr.xml $dir
cp -v *.properties $dir
explode_war
swap_http_client
update_war
