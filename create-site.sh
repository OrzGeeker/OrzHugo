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

read -p "Please input a project name: " project_name

if [ -z "$project_name" ];
then
    echo the project name is empty!!!
    exit -1
fi

if [ -d $project_name ];
then
    read -p "$project_name exist, would you overwrite it? " i
    case $i in
        y|Y|yes|Yes)
            rm -rf $project_name
            ;;
        *)
            echo "$project_name exist, not modify"
            exit -2
            ;;
    esac
fi

mkdir -p $project_name

cd $project_name

git init

read -p "Please input a site name you will create: " site_name

if [ -z "$site_name" ];
then
    echo the site name is empty!!!
    exit -1
fi

if [ -d $site_name ];
then
    read -p "$site_name exist, would you overwrite it? " i
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
select theme_option in "ananke" "swift" "binario" "learn" "dream" "personal"
do
    case $theme_option in 
        "ananke")
            theme_url="https://github.com/budparr/gohugo-theme-ananke.git"
            break;;
        "swift")
            theme_url="https://github.com/onweru/hugo-swift-theme.git"
            break;;
        "binario")
            theme_url="https://github.com/Vimux/Binario.git"
            break;;
        "learn")
            theme_url="https://github.com/matcornic/hugo-theme-learn.git"
            break;;
        "dream")
            theme_url="https://github.com/g1eny0ung/hugo-theme-dream.git"
            break;;
        "personal")
            theme_url="https://github.com/bjacquemet/personal-web.git"
            break;;
    esac
done

theme_dir="themes/$theme_option"
git submodule add $theme_url $theme_dir

read -p "Please select a url for this site if you have a domain: " base_url

if [ -z "$base_url" ];
then
    base_url="https://example.org"
fi

cat > config.toml <<EOF
baseURL = "$base_url"
languageCode = "en-us"
title = "$site_name"
theme = "$theme_option"
EOF

cd ..

publish_script_name="publish_site.sh"
preview_script_name="preview_site.sh"

cat > $publish_script_name << EOF
# !/usr/bin/env bash
# -*- coding: utf-8 -*-

if [ "\`git status -s\`" ]
then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

SITE_ROOT="$site_name"
SITE_PUB_DIR="\${SITE_ROOT}/public"
SITE_CONTENT_DIR="\${SITE_ROOT}/content"
SITE_THEME_DIR="\${SITE_ROOT}/themes"

echo "Deleting old publication"
rm -rf \${SITE_PUB_DIR}
git worktree prune
rm -rf .git/worktrees/\${SITE_PUB_DIR}

echo "Checking out gh-pages branch into public"
git worktree add \${SITE_PUB_DIR} -B gh-pages

echo "Removing existing files"
rm -rf \${SITE_PUB_DIR}/*

echo "$base_url" > \${SITE_PUB_DIR}/CNAME

echo "Generating site"
hugo -s "\${SITE_ROOT}" -e production

echo "Updating gh-pages branch"
cd \${SITE_PUB_DIR} && git add --all && git commit -m "Publishing to gh-pages (publish.sh)"

echo "Pushing to github"
cd - 
git push --all
open "http://$base_url"

EOF

cat > $preview_script_name << EOF
#!/usr/bin/env bash
#-*- utf-8 -*-

pkill -9 hugo
hugo -s $site_name server -D &
sleep 2s
open http://localhost:1313

EOF

sudo chmod u+x $publish_script_name $preview_script_name

cat > .gitignore <<EOF
.DS_Store
${site_name}/public
EOF

hugo -s $site_name new  post_demo.md

pkill -9 hugo
hugo -s $site_name server  -D &
sleep 2s
open http://localhost:1313

