#!/bin/bash

# логіка така: скрипт запускається cron на бекап-сервері, підключається до іншого сервера і копіює необхідні папки
# Full-бекап запускається раз в тиждень
# Diff-бекап запускається щодня
set -x
bdir=/var/backup	# директорія де зберігаються бекапи. Містить 6 папок: dbase, diff, fbase, full, log, restor

sdir1=`echo $2`		# папки на віддаленому сервері, об'єкти бекапу 
sdir2=`echo $3`
sdir3=`echo $4`
sdir4=`echo $5`
sdir5=`echo $6`

slog=/var/backup/savelog		# повідомлення, що надсилається у випадку невдачі на пошту
elog=/var/backup/log/errorlog		# записуються помилки під час бекапу
rlog=/var/backup/restorlog		# записуються помилки під час відновлення

email=sergii@localhost			# поштова скринька
rotate="/usr/sbin/logrotate -f"		# ротація архівів бекапів і логів

case $1 in

#FULL
[f])
	date=`date +%a_%d-%m-%Y_%T`
	echo "Full backup started: " $date > $slog
	echo "Full backup " $date >> $elog

	tar --numeric-owner -czpf $bdir/full/fbackup.tar.gz $bdir/fbase/ 2>> $elog
	sleep 2
	$rotate /etc/logrotate_full.conf 2>> $elog
	sleep 2
	rsync -avz --delete -e ssh $sdir1 $sdir2 $sdir3 $sdir4 $sdir5 $bdir/fbase/ 2>> $elog

	if [ $? -eq 0 ]; then
		echo "Backup $sdir1 $sdir2 $sdir3 $sdir4 $sdir5 success" >> $slog
	else
		echo "Backup $sdir1 $sdir2 $sdir3 $sdir4 $sdir5 not processed" >> $slog
		cat $slog | mail $email
	fi
	
	$rotate /etc/logrotate_log.conf 2>>$elog
	echo "Full backup finished: " `date +%a_%d-%m-%Y_%T` >> $slog
	cp -f $slog $bdir/fbase/
	;;
#DIFF
[d])
	date=`date +%a_%d-%m-%Y_%T`
	echo "Diff backup started: " $date > $slog
	echo "Diff backup " $date >> $elog

	tar --numeric-owner -czpf $bdir/diff/dbackup.tar.gz $bdir/dbase/ 2>> $elog
	sleep 2
	$rotate /etc/logrotate_diff.conf 2>> $elog
	sleep 2
	rsync -avz --delete --compare-dest=$bdir/fbase/ $sdir1 $sdir2 $sdir3 $sdir4 $sdir5 $bdir/dbase 2>> $elog

	if [ $? -eq 0 ]; then
		echo "Backup $sdir1 $sdir2 $sdir3 $sdir4 $sdir5 success" >> $slog
	else
		echo "Backup $sdir1 $sdir2 $sdir3 $sdir4 $sdir5 NOT processed" >> $slog
		cat $slog | mail $email
	fi
	
	echo "-------" >> $elog
	echo "Diff backup finished: " `date +%a_%d-%m-%Y_%T` >> $slog
	cp -f $slog $bdir/dbase/
	;;
#CRETE BACKUP DIRS
[c])
	mkdir $bdir
	mkdir $bdir/dbase
	mkdir $bdir/diff
	mkdir $bdir/fbase
	mkdir $bdir/full
	mkdir $bdir/log
	mkdir $bdir/restor
	echo "Stvoreno!"
	;;
#REMOVE BACKUP FILES
[r])
	rm -rf $bdir/dbase/*
	rm -rf $bdir/diff/*
	rm -rf $bdir/fbase/*
	rm -rf $bdir/full/*
	rm -rf $bdir/log/*
	rm -rf $bdir/restor/*
	echo " " > $slog
	echo " " > $rlog
	echo "Vudaleno!"
	;;
#RESTORE FULL BACRUP
"rf")
	echo "Full restore " `date +%a_%d-%m-%Y_%T` > $rlog
	if [ $2 = 1 ]; then
		rsync -a $bdir/fbase/ $bdir/restor/ >> $rlog
	elif [ $2 = 2 ]; then
		tar -xpf $bdir/full/*.1 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 3 ]; then
		tar -xpf $bdir/full/*.2 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 4 ]; then
		tar -xpf $bdir/full/*.3 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 5 ]; then
		tar -xpf $bdir/full/*.4 -C $bdir/restor/ --strip-components=3 >> $rlog
	fi
	echo "-------" >> $rlog
;;
#RESTORE DIFF BACKUP
"rd")
	echo "Diff restore " `date +%a_%d-%m-%Y_%T` >> $rlog
	if [ $2 = 1 ]; then
		rsync -au $bdir/dbase/ $bdir/restor/ >> $rlog
	elif [ $2 = 2 ]; then
		tar -xpf $bdir/diff/*.1 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 3 ]; then
		tar -xpf $bdir/diff/*.2 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 4 ]; then
		tar -xpf $bdir/diff/*.3 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 5 ]; then
		tar -xpf $bdir/diff/*.4 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 6 ]; then
		tar -xpf $bdir/diff/*.5 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 7 ]; then
		tar -xpf $bdir/diff/*.6 -C $bdir/restor/ --strip-components=3 >> $rlog
	elif [ $2 = 8 ]; then
		tar -xpf $bdir/diff/*.7 -C $bdir/restor/ --strip-components=3 >> $rlog
	fi
;;
esac
