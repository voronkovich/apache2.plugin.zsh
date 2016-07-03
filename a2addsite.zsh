#!/usr/bin/env zsh

PROGNAME=${0##*/}

function usage() {
    cat <<EOF
Usage: $PROGNAME [OPTIONS] SITE NAME... SITE PATH...

Options:
    -t template name
    -l add site to /etc/hosts
    -h show this output

Examples:
    $PROGNAME -lt symfony mysite.loc /var/www/mysite.loc
    $PROGNAME mysite.loc ./public_html/mysite.loc
EOF
}

function render_site_template() {
    if [[ -n $APACHE_SITES_CUSTOM_TEMPLATES && -f $APACHE_SITES_CUSTOM_TEMPLATES/$TEMPLATE ]]; then
        TMPL=$APACHE_SITES_CUSTOM_TEMPLATES/$TEMPLATE
    elif [[ -f $APACHE_SITES_TEMPLATES/$TEMPLATE ]]; then
        TMPL=$APACHE_SITES_TEMPLATES/$TEMPLATE
    else
        echo "Error: template $TEMPLATE not found" 1>&2
        exit 1
    fi

    sed \
        -e "s|\${SITE_NAME}|$SITE_NAME|" \
        -e "s|\${SITE_PATH}|$SITE_PATH|" \
        $TMPL
}

function add_to_hosts() {
    if [[ ! -f $HOSTS_FILE ]]; then
        echo "Error: file $HOSTS_FILE not exists" 1>&2
        exit 1
    fi
    if [[ ! -w $HOSTS_FILE ]]; then
        echo "Error: file $HOSTS_FILE not writable" 1>&2
        exit 1
    fi
    if [[ `grep -c "$SITE_NAME\$" $HOSTS_FILE` == 0 ]]; then
        echo -e "127.0.0.1\t$SITE_NAME" >> $HOSTS_FILE
        echo -e "127.0.0.1\twww.$SITE_NAME" >> $HOSTS_FILE
    else
        echo "Warning: $SITE_NAME is already exists in hosts file" 1>&2
    fi
}

zparseopts -D t:=template -help=help -h=help h=help l=local

if [[ -n $help ]]; then
    usage
    exit
fi

if [[ -n $template ]]; then
    TEMPLATE=$template[2]
else
    TEMPLATE=default
fi

if [[ -z $APACHE_SITES_TEMPLATES ]]; then
    APACHE_SITES_TEMPLATES=$(dirname $(readlink -f $0))/templates
fi

if [[ ! -z $APACHE_SITES_CUSTOM_TEMPLATES && ! -d $APACHE_SITES_CUSTOM_TEMPLATES ]]; then
    echo "Warning: path $APACHE_SITES_CUSTOM_TEMPLATES not exists" 1>&2
    APACHE_SITES_CUSTOM_TEMPLATES=APACHE_SITES_TEMPLATES
fi

# Checking directory with available sites
if [[ -z $APACHE_SITES_AVAILABLE && -d /etc/apache2/sites-available ]]; then
    APACHE_SITES_AVAILABLE=/etc/apache2/sites-available
elif [[ ! -d $APACHE_SITES_AVAILABLE ]]; then
    echo "Error: directory with virtual hosts not found" 1>&2
    exit 1
fi
if [[ ! -w $APACHE_SITES_AVAILABLE ]]; then
    echo "Error: directory with virtual hosts not writable" 1>&2
    exit 1
fi

SITE_NAME=$1
SITE_PATH=$(readlink -f ${2:="."} 2&>/dev/null)

if [[ -z $SITE_NAME ]]; then
    echo "Error: site name is required" 1>&2
    exit 1
fi

if [[ -f $APACHE_SITES_AVAILABLE/$SITE_NAME ]]; then
    echo "Error: site $SITE_NAME already exists" 1>&2
    exit 1
fi 

if [[ ! -d $SITE_PATH ]]; then
    echo "Warning: site path $SITE_PATH not exists" 1>&2
fi 

render_site_template > $APACHE_SITES_AVAILABLE/$SITE_NAME.conf

if [[ -n $local ]]; then
    if [[ -z $HOSTS_FILE ]]; then
        HOSTS_FILE=/etc/hosts
    fi
    add_to_hosts
fi
