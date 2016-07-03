export ZSH_PLUGIN_APACHE_PATH=$(dirname $(readlink -f $0))
export ZSH_PLUGIN_APACHE_SITES_TEMPLATES=$ZSH_PLUGIN_APACHE_PATH/templates
if [[ -z $ZSH_PLUGIN_APACHE_SITES_AVAILABLE ]]; then
    export ZSH_PLUGIN_APACHE_SITES_AVAILABLE=/etc/apache2/sites-available
fi

alias a2rl="sudo service apache2 reload"
alias a2rs="sudo service apache2 restart"
alias a2ens="sudo a2ensite"
alias a2dis="sudo a2dissite"
alias a2enm="sudo a2enmod"
alias a2dim="sudo a2dismod"

a2as() {
    if [[ $# -eq 0 || $(echo $* | grep -ce '-h') -gt 0 ]]; then
        $ZSH_PLUGIN_APACHE_PATH/a2addsite.zsh --help 
        return 1
    else
        sudo \
            APACHE_SITES_AVAILABLE=$ZSH_PLUGIN_APACHE_SITES_AVAILABLE \
            APACHE_SITES_TEMPLATES=$ZSH_PLUGIN_APACHE_SITES_TEMPLATES \
            APACHE_SITES_CUSTOM_TEMPLATES=$ZSH_PLUGIN_APACHE_SITES_CUSTOM_TEMPLATES \
            $ZSH_PLUGIN_APACHE_PATH/a2addsite.zsh $*
    fi
}

a2gs() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: a2gs SITE NAME..."
        return 1
    fi
    cd $(sed -ne 's/[[:space:]]*DocumentRoot[[:space:]]\+\([^[:space:]]*\)/\1/p' $ZSH_PLUGIN_APACHE_SITES_AVAILABLE/$1) 
}

a2es() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: a2es SITE NAME..."
        return 1
    fi
    if [[ -z $EDITOR ]]; then
        echo "Error: variable \$EDITOR not defined" 1>&2
        return 1
    fi
    sudo $EDITOR $ZSH_PLUGIN_APACHE_SITES_AVAILABLE/$1
}

remove_from_hosts() {
    sudo sed -i".bak" "/$SITE_NAME/d" $HOSTS_FILE
}

a2ds() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: a2ds SITE NAME...\nOptions:\n\t-l Remove from hosts file."
        return 1
    fi
    zparseopts -D -E l=local
    sudo a2dissite $1 > /dev/null
    sudo rm $ZSH_PLUGIN_APACHE_SITES_AVAILABLE/$1.conf
    if [[ -n $local ]]; then
        if [[ -z $HOSTS_FILE ]]; then
            HOSTS_FILE=/etc/hosts
        fi
        SITE_NAME=$1
        remove_from_hosts
    fi
}

_a2site() {
    _files -W $ZSH_PLUGIN_APACHE_SITES_AVAILABLE
}

compdef _a2site a2es
compdef _a2site a2gs
compdef _a2site a2ds
