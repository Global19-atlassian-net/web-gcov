#!/bin/sh

source ./config.sh
export LC_ALL=C

# file that contains the PHP version tags
FILENAME=tags.inc

WORKDIR=`dirname "$0"`
echo "$WORKDIR" | grep -q '^/' || WORKDIR="`pwd`/$WORKDIR"  # get absolute path

# make genhtml use our header/footer
export LTP_GENHTML="genhtml --html-prolog ${WORKDIR}/lcov_prolog.inc --html-epilog ${WORKDIR}/lcov_epilog.inc --html-extension php"

# set up a one dimensional array to store all php version information
declare -a TAGS_ARRAY
TAGS_ARRAY=( `cat "$FILENAME"` )

# Calculate how many elements there are in a php version array
TAGS_COUNT=${#TAGS_ARRAY[@]}

BUILT_SOME=0

# Check for a build version passed to the script
if [ $# -eq 1 ]; then
	BUILD=$1
else
	BUILD="_all_"
fi

# loop through each PHP version and perform the required builds
for (( i = 0 ; i < $TAGS_COUNT ; i += 1 ))
do
	PHPTAG=${TAGS_ARRAY[i]}

	# Build all has no exceptions
	if [ $BUILD = "_all_" ]; then
		BUILD_VERSION=1
	else
		if [ $BUILD = $PHPTAG ]; then
			BUILD_VERSION=1
		else
			BUILD_VERSION=0
		fi
	fi

	# If this version should be built
	if [ $BUILD_VERSION = 1 ]; then

		BUILT_SOME=1
		BEGIN=`date +%s`

		OUTDIR=${OUTROOT}/${PHPTAG}
		PHPSRC=${PHPROOT}/${PHPTAG}
		TMPDIR=${PHPROOT}/tmp/${PHPTAG}

		mkdir -p $OUTDIR
		mkdir -p $TMPDIR

		cd ${PHPROOT}
		if [ -d ${PHPTAG} ]; then
			cd ${PHPTAG}
			cvs -q up
			# CVS doesn't update the Zend dir automatically
			cd Zend
			cvs -q up
			cd ..
		else
			cvs -q -d ${CVSROOT} co -d ${PHPTAG} -r ${PHPTAG} php-src
			cd ${PHPTAG}
		fi
		./cvsclean
		./buildconf --force > /dev/null

		if [ -x ./config.nice ]; then
			./config.nice > /dev/null
		else
			# try to run with the default options
			./configure > /dev/null
		fi

		if ( make > /dev/null 2> ${TMPDIR}/php_build.log ); then

			MAKESTATUS=pass

			TEST_PHP_ARGS="-U -n -q --keep-all"

			# only run valgrind testing if it is available
			if (valgrind --version >/dev/null 2>&1 && test "$VALGRIND" ); then
				TEST_PHP_ARGS+=" -m"
			fi

			export TEST_PHP_ARGS

			# test for lcov support
			if ( grep lcov Makefile >/dev/null 2>&1 ); then
				make lcov > ${TMPDIR}/php_test.log
				rm -fr ${OUTDIR}/lcov_html
				mv lcov_html ${OUTDIR}
			else
				make test > ${TMPDIR}/php_test.log
			fi

			echo "make successful: ${PHPTAG}"
		else
			MAKESTATUS=fail
			echo "make failed"
		fi # End build failure or success

		BUILD_TIME=$[`date +%s` - ${BEGIN}]

		php ${WORKDIR}/cron.php ${TMPDIR} ${OUTDIR} ${PHPSRC} ${MAKESTATUS} ${PHPTAG} ${BUILD_TIME}

	fi # End verify build PHP version
done


# display an error if the tag doesn't exist
if [ $BUILT_SOME = 0 ]; then
	echo "Invalid tag specified: '$BUILD'"
	echo
	exit 1
fi
