# !/usr/bin/env bash
# -*- coding: utf-8 -*-

which brew > /dev/null
if [ $? -ne 0 ];
then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

which hugo > /dev/null
if [ $? -ne 0 ];
then
    brew install hugo
fi

hugo version > /dev/null
if [ $? -ne 0 ];
then
    echo hugo install failed!
    exit -1
fi

read -p "Please input a site name you will create: " site_name


if [ -z "site_name" ];
then
    echo the site name is empty!!!
    exit -1
fi

if [ -d $site_name ];
then
    read -p "$site_name exist, would you delete it? " i
    case $i in
        y|Y|yes|Yes)
            rm -rf $site_name
            ;;
        *)
            echo "$site_name exist, not modify"
            exit -2
            ;;
    esac
fi

hugo new site "$site_name"

git version > /dev/null
if [ $? -ne 0 ];
then
    brew install git
fi

cd $site_name

echo
echo

PS3="select a theme for site $site_name: "
select theme_option in "ananke" "swift" "binario" "learn" "dream"
do
    case $theme_option in 
        "ananke")
            theme_url="https://github.com/budparr/gohugo-theme-ananke.git"
            break;;
        "swift")
            theme_url="https://github.com/onweru/hugo-swift-theme.git"
            break;;
        "binario")
            theme_url="https://github.com/vimux/binario"
            break;;
        "learn")
            theme_url="https://github.com/matcornic/hugo-theme-learn.git"
            break;;
        "dream")
            theme_url="https://github.com/g1eny0ung/hugo-theme-dream.git"
            break;;
    esac
done

url_exp_pattern="^[a-zA-z]+://[^\s]*$"

echo $theme_url | grep -oE $url_exp_pattern

if [ $? -ne 0 ];
then
    echo "$theme_url is not a valid link"
    exit -3
fi

git init
theme_dir="themes/$theme_option"
git submodule add $theme_url $theme_dir

cat > config.toml <<EOF
baseURL = "https://example.org/"
languageCode = "en-us"
title = "$site_name"
theme = "$theme_option"
EOF

hugo new post_demo.md

hugo server -D
