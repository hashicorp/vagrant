# runs all transforms needed for a fresh content port

sh _temporary_scripts/rename.sh pages/docs;
sh _temporary_scripts/rename.sh pages/vmware;
sh _temporary_scripts/rename.sh pages/intro;
node _temporary_scripts/fix_unclosed_tags.js;
node _temporary_scripts/fix_partials.js;
