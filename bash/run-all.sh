#!/bin/bash

# generate HOME_PATH workspace by running prepare.sh first
HOME_PATH=/data/v4

# dataset basic info
DATASET=BallSpeed # BallSpeed KOB MF03 RcvTime
DEVICE="root.game"
MEASUREMENT="s6"
DATA_TYPE=long # long or double
TIMESTAMP_PRECISION=ns
DATA_MIN_TIME=0  # in the corresponding timestamp precision
DATA_MAX_TIME=617426057626  # in the corresponding timestamp precision
TOTAL_POINT_NUMBER=1200000
let TOTAL_TIME_RANGE=${DATA_MAX_TIME}-${DATA_MIN_TIME} # check what if not +1 what the difference
VALUE_ENCODING=PLAIN
TIME_ENCODING=PLAIN
COMPRESSOR=UNCOMPRESSED

# iotdb config info
IOTDB_CHUNK_POINT_SIZE=100

# exp controlled parameter design
FIX_W=1000
FIX_QUERY_RANGE=$TOTAL_TIME_RANGE
FIX_OVERLAP_PERCENTAGE=10
FIX_DELETE_PERCENTAGE=49
FIX_DELETE_RANGE=10

hasHeader=false # default

############################
# Experimental parameter design:
#
# [EXP1] Varying the number of time spans w
# (1) w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
#
# [EXP2] Varying query time range
# (1) w: 1000
# (2) query range: 1%,5%,10%,20%,40%,60%,80%,100% of totalRange
# - corresponding estimated chunks per interval = 1%,5%,10%,20%,40%,60%,80%,100% of kmax
# - kMax=(pointNum/chunkSize)/w, when range = 100% of totalRange.
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
#
# [EXP3] Varying chunk overlap percentage
# (1) w: 1000
# (2) query range: totalRange
# (3) overlap percentage: 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%
# (4) delete percentage: 0%
# (5) delete time range: 0
#
# [EXP4] Varying delete percentage
# (1) w: 1000
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%, 9%, 19%, 29%, 39%, 49%, 59%, 69%, 79%, 89%
# (5) delete time range: 10% of chunk time interval, that is 0.1*totalRange/(pointNum/chunkSize)
#
# [EXP5] Varying delete time range
# (1) w: 1000
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 49%
# (5) delete time range: 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90% of chunk time interval, that is x%*totalRange/(pointNum/chunkSize)
############################
# O_10_D_0_0

# O_20_D_0_0
# O_30_D_0_0
# O_40_D_0_0
# O_50_D_0_0
# O_60_D_0_0
# O_70_D_0_0
# O_80_D_0_0
# O_90_D_0_0

# O_10_D_9_10
# O_10_D_19_10
# O_10_D_29_10
# O_10_D_39_10
# O_10_D_49_10
# O_10_D_59_10
# O_10_D_69_10
# O_10_D_79_10
# O_10_D_89_10

# O_10_D_49_20
# O_10_D_49_30
# O_10_D_49_40
# O_10_D_49_50
# O_10_D_49_60
# O_10_D_49_70
# O_10_D_49_80
# O_10_D_49_90
############################

echo 3 |sudo tee /proc/sys/vm/drop_cache
free -m
echo "Begin experiment!"

############################
# prepare out-of-order source data.
# Vary overlap percentage: 0%, 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%
############################
echo "prepare out-of-order source data"
cd $HOME_PATH/${DATASET}
cp ${DATASET}.csv ${DATASET}-O_0
# java OverlapGenerator iotdb_chunk_point_size dataType inPath outPath timeIdx valueIdx overlapPercentage overlapDepth
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_10 0 1 10 10 ${hasHeader}
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_20 0 1 20 10 ${hasHeader}
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_30 0 1 30 10 ${hasHeader}
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_40 0 1 40 10 ${hasHeader}
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_50 0 1 50 10 ${hasHeader}
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_60 0 1 60 10 ${hasHeader}
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_70 0 1 70 10 ${hasHeader}
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_80 0 1 80 10 ${hasHeader}
java OverlapGenerator ${IOTDB_CHUNK_POINT_SIZE} ${DATA_TYPE} ${DATASET}.csv ${DATASET}-O_90 0 1 90 10 ${hasHeader}

############################
# O_10_D_0_0
############################

cd $HOME_PATH/${DATASET}_testspace
mkdir O_10_D_0_0
cd O_10_D_0_0

# prepare IoTDB config properties
$HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_O_10_D_0_0/system ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_O_10_D_0_0/data ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_O_10_D_0_0/wal ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh group_size_in_byte 1073741824 ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh compressor ${COMPRESSOR} ../../iotdb-engine-example.properties
$HOME_PATH/tool.sh error_Param 50 ../../iotdb-engine-example.properties

# properties for cpv
$HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
# properties for moc
$HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

# [write data]
echo "Writing O_10_D_0_0"
cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
cd $HOME_PATH/iotdb-server-0.12.4/sbin
./start-server.sh /dev/null 2>&1 &
sleep 8s
# Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx VALUE_ENCODING
java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_10 0 0 0 1 ${VALUE_ENCODING} ${hasHeader}
sleep 5s
./stop-server.sh
sleep 5s
echo 3 | sudo tee /proc/sys/vm/drop_caches


# [query data]
echo "Querying O_10_D_0_0 with varied w"
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
mkdir vary_w

echo "mac"
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_w
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w mac >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultMAC.csv
  let i+=1
done

echo "cpv"
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_w
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
do
  echo "w=$w"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} $w cpv >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultCPV.csv
  let i+=1
done

# unify results
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_w
cp $HOME_PATH/SumResultUnify.* .
# java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv
java SumResultUnify sumResultMAC.csv sumResultCPV.csv result.csv

# export results
# [EXP1]
# w: 1,2,5,10,20,50,100,200,500,1000,2000,4000,8000
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
cd vary_w
cat result.csv >$HOME_PATH/${DATASET}_testspace/exp1.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp1, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/w,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp1.csv
line=2
for w in 1 2 5 10 20 50 100 200 500 1000 2000 4000 8000
do
  #let c=${pointNum}/${chunkSize}/$w # note bash only does the integer division
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/$w) | bc )
  sed -i -e ${line}"s/^/${w},${c},/" $HOME_PATH/${DATASET}_testspace/exp1.csv
  let line+=1
done

(cut -f 1 -d "," $HOME_PATH/${DATASET}_testspace/exp1.csv) > tmp1.csv
(cut -f 4 -d "," $HOME_PATH/${DATASET}_testspace/exp1.csv| paste -d, tmp1.csv -) > tmp2.csv
(cut -f 71 -d "," $HOME_PATH/${DATASET}_testspace/exp1.csv| paste -d, tmp2.csv -) > tmp3.csv
echo "param,M4(ns),M4-LSM(ns)" > $HOME_PATH/${DATASET}_testspace/exp1_res.csv
sed '1d' tmp3.csv >> $HOME_PATH/${DATASET}_testspace/exp1_res.csv
rm tmp1.csv
rm tmp2.csv
rm tmp3.csv

############################
# [EXP2] Varying query time range
# (1) w: 100
# (2) query range: 1%,5%,10%,20%,40%,60%,80%,100% of totalRange
# - corresponding estimated chunks per interval = 1%,5%,10%,20%,40%,60%,80%,100% of kmax
# - kMax=(pointNum/chunkSize)/w, when range = 100% of totalRange.
# (3) overlap percentage: 10%
# (4) delete percentage: 0%
# (5) delete time range: 0
############################
echo "Querying O_10_D_0_0 with varied tqe"

cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
mkdir vary_tqe

# echo "moc"
# cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_tqe
# mkdir moc
# cd moc
# cp $HOME_PATH/ProcessResult.* .
# cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
# i=1
# for per in 1 5 10 20 40 60 80 # 100% is already done in exp1
# do
#   range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
#   echo "per=${per}% of ${TOTAL_TIME_RANGE}, range=${range}"
#   #  range=$((echo scale=0 ; echo ${k}*${FIX_W}*${TOTAL_TIME_RANGE}*${IOTDB_CHUNK_POINT_SIZE}/${TOTAL_POINT_NUMBER}) | bc )
#   # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
#   $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${range} ${FIX_W} moc >> result_${i}.txt
#   java ProcessResult result_${i}.txt result_${i}.out ../sumResultMOC.csv
#   let i+=1
# done

echo "mac"
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_tqe
mkdir mac
cd mac
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for per in 1 5 10 20 40 60 80 # 100% is already done in exp1
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  echo "per=${per}% of ${TOTAL_TIME_RANGE}, range=${range}"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${range} ${FIX_W} mac >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultMAC.csv
  let i+=1
done

echo "cpv"
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_tqe
mkdir cpv
cd cpv
cp $HOME_PATH/ProcessResult.* .
cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
i=1
for per in 1 5 10 20 40 60 80 # 100% is already done in exp1
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  echo "per=${per}% of ${TOTAL_TIME_RANGE}, range=${range}"
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${range} ${FIX_W} cpv >> result_${i}.txt
  java ProcessResult result_${i}.txt result_${i}.out ../sumResultCPV.csv
  let i+=1
done

# unify results
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0/vary_tqe
cp $HOME_PATH/SumResultUnify.* .
# java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv
java SumResultUnify sumResultMAC.csv sumResultCPV.csv result.csv

# export results
# [EXP2]
# w: 100
# query range: k*w*totalRange/(pointNum/chunkSize).
# - target estimated chunks per interval = k
# - range = k*w*totalRange/(pointNum/chunkSize)
# - kMax=(pointNum/chunkSize)/w, that is, range=totalRange.
# - E.g. k=0.2,0.5,1,2.5,5,12
# overlap percentage: 10%
# delete percentage: 0%
# delete time range: 0
cd $HOME_PATH/${DATASET}_testspace/O_10_D_0_0
cd vary_tqe
cat result.csv >$HOME_PATH/${DATASET}_testspace/exp2.csv

# 把exp1里FIX_W的那一行结果追加到exp2.csv最后一行，且不要前两列
# append the line starting with FIX_W and without the first two columns in exp1.csv to exp2.csv
sed -n -e "/^${FIX_W},/p" $HOME_PATH/${DATASET}_testspace/exp1.csv > tmp # the line starting with FIX_W
cut -d "," -f 3- tmp >> $HOME_PATH/${DATASET}_testspace/exp2.csv # without the first two columns
rm tmp

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp2, estimated chunks per interval=k
sed -i -e 1's/^/range,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp2.csv
line=2
for per in 1 5 10 20 40 60 80 100 # 100% is already done in exp1
do
  range=$((echo scale=0 ; echo ${per}*${TOTAL_TIME_RANGE}/100) | bc )
  c=$((echo scale=0 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_W}*${per}/100) | bc )
  sed -i -e ${line}"s/^/${range},${c},/" $HOME_PATH/${DATASET}_testspace/exp2.csv
  let line+=1
done

(cut -f 1 -d "," $HOME_PATH/${DATASET}_testspace/exp2.csv) > tmp1.csv
(cut -f 4 -d "," $HOME_PATH/${DATASET}_testspace/exp2.csv| paste -d, tmp1.csv -) > tmp2.csv
(cut -f 71 -d "," $HOME_PATH/${DATASET}_testspace/exp2.csv| paste -d, tmp2.csv -) > tmp3.csv
echo "param,M4(ns),M4-LSM(ns)" > $HOME_PATH/${DATASET}_testspace/exp2_res.csv
sed '1d' tmp3.csv >> $HOME_PATH/${DATASET}_testspace/exp2_res.csv
rm tmp1.csv
rm tmp2.csv
rm tmp3.csv

############################
# [EXP3] Varying chunk overlap percentage
# (1) w: 1000
# (2) query range: totalRange
# (3) overlap percentage: 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%
# (4) delete percentage: 0%
# (5) delete time range: 0
############################
for overlap_percentage in 20 30 40 50 60 70 80 90
do
  workspace="O_${overlap_percentage}_D_0_0"
  cd $HOME_PATH/${DATASET}_testspace
  mkdir ${workspace}
  cd ${workspace}

  # prepare IoTDB config properties
  $HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/system ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_${workspace}/data ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/wal ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh group_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compressor ${COMPRESSOR} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh error_Param 50 ../../iotdb-engine-example.properties
  # properties for cpv
  $HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
  # properties for moc
  $HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

  # [write data]
  echo "Writing ${workspace}"
  cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 8s
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx VALUE_ENCODING
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_${overlap_percentage} 0 0 0 1 ${VALUE_ENCODING} ${hasHeader}
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

  # [query data]
  echo "Querying ${workspace}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}
  mkdir fix

  # echo "moc"
  # cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  # mkdir moc
  # cd moc
  # cp $HOME_PATH/ProcessResult.* .
  # cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  # $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} moc >> result_3.txt
  # java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

  echo "mac"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir mac
  cd mac
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} mac >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

  echo "cpv"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir cpv
  cd cpv
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

  # unify results
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  cp $HOME_PATH/SumResultUnify.* .
  # java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv
  java SumResultUnify sumResultMAC.csv sumResultCPV.csv result.csv
done

# export results
# [EXP3]
# w: 100
# query range: totalRange
# overlap percentage: 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%
# delete percentage: 0%
# delete time range: 0

cd $HOME_PATH/${DATASET}_testspace/O_20_D_0_0
cd fix
sed -n '1,1p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv #only copy header

# overlap percentage 10% exp result
# 把exp1.csv里的w=FIX_W那一行复制到exp3.csv里作为overlap percentage 10%的结果
# append the line starting with FIX_W and without the first two columns in exp1.csv to exp3.csv
# sed -n '8,8p' $HOME_PATH/${DATASET}_testspace/exp1.csv >> $HOME_PATH/${DATASET}_testspace/exp4.csv
sed -n -e "/^${FIX_W},/p" $HOME_PATH/${DATASET}_testspace/exp1.csv > tmp # the line starting with FIX_W
cut -d "," -f 3- tmp >> $HOME_PATH/${DATASET}_testspace/exp3.csv # without the first two columns
rm tmp

# overlap percentage 20% exp result
cd $HOME_PATH/${DATASET}_testspace/O_20_D_0_0
cd fix
# cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

# overlap percentage 30% exp result
cd $HOME_PATH/${DATASET}_testspace/O_30_D_0_0
cd fix
# cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

# overlap percentage 40% exp result
cd $HOME_PATH/${DATASET}_testspace/O_40_D_0_0
cd fix
# cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

# overlap percentage 50% exp result
cd $HOME_PATH/${DATASET}_testspace/O_50_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

# overlap percentage 60% exp result
cd $HOME_PATH/${DATASET}_testspace/O_60_D_0_0
cd fix
# cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

# overlap percentage 70% exp result
cd $HOME_PATH/${DATASET}_testspace/O_70_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

# overlap percentage 80% exp result
cd $HOME_PATH/${DATASET}_testspace/O_80_D_0_0
cd fix
# cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

# overlap percentage 90% exp result
cd $HOME_PATH/${DATASET}_testspace/O_90_D_0_0
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp3.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp3, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/overlap percentage,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp3.csv
line=2
for op in 10 20 30 40 50 60 70 80 90
do
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_W}) | bc )
  sed -i -e ${line}"s/^/${op},${c},/" $HOME_PATH/${DATASET}_testspace/exp3.csv
  let line+=1
done

(cut -f 1 -d "," $HOME_PATH/${DATASET}_testspace/exp3.csv) > tmp1.csv
(cut -f 4 -d "," $HOME_PATH/${DATASET}_testspace/exp3.csv| paste -d, tmp1.csv -) > tmp2.csv
(cut -f 71 -d "," $HOME_PATH/${DATASET}_testspace/exp3.csv| paste -d, tmp2.csv -) > tmp3.csv
echo "param,M4(ns),M4-LSM(ns)" > $HOME_PATH/${DATASET}_testspace/exp3_res.csv
sed '1d' tmp3.csv >> $HOME_PATH/${DATASET}_testspace/exp3_res.csv
rm tmp1.csv
rm tmp2.csv
rm tmp3.csv

############################
# [EXP4] Varying delete percentage
# (1) w: 1000
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 0%, 9%, 19%, 29%, 39%, 49%, 59%, 69%, 79%, 89%
# (5) delete time range: 10% of chunk time interval, that is 0.1*totalRange/(pointNum/chunkSize)
############################
# O_10_D_9_10
for delete_percentage in 9 19 29 39 49 59 69 79 89
do
  workspace="O_10_D_${delete_percentage}_10"
  cd $HOME_PATH/${DATASET}_testspace
  mkdir ${workspace}
  cd ${workspace}

  # prepare IoTDB config properties
  $HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/system ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_${workspace}/data ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/wal ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh group_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compressor ${COMPRESSOR} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh error_Param 50 ../../iotdb-engine-example.properties
  # properties for cpv
  $HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
  # properties for moc
  $HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

  # [write data]
  echo "Writing ${workspace}"
  cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 10s
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx VALUE_ENCODING
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_10 ${delete_percentage} ${FIX_DELETE_RANGE} 0 1 ${VALUE_ENCODING} ${hasHeader}
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

  # [query data]
  echo "Querying ${workspace}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}
  mkdir fix

  # echo "moc"
  # cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  # mkdir moc
  # cd moc
  # cp $HOME_PATH/ProcessResult.* .
  # cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  # $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} moc >> result_3.txt
  # java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

  echo "mac"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir mac
  cd mac
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} mac >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

  echo "cpv"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir cpv
  cd cpv
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

  # unify results
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  cp $HOME_PATH/SumResultUnify.* .
  # java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv
  java SumResultUnify sumResultMAC.csv sumResultCPV.csv result.csv
done

# export results
# [EXP4]
# w: 100
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 0%, 9%, 19%, 29%, 39%, 49%, 59%, 69%, 79%, 89%
# delete time range: 10% of chunk time interval, that is 0.1*totalRange/(pointNum/chunkSize)

# only copy the header
cd $HOME_PATH/${DATASET}_testspace/O_10_D_29_10
cd fix
sed -n '1,1p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv #只是复制表头

# delete percentage 0% exp result
# 把exp1.csv里的w=FIX_W那一行复制到exp4.csv里作为delete percentage 0%的结果
# append the line starting with FIX_W and without the first two columns in exp1.csv to exp4.csv
# sed -n '8,8p' $HOME_PATH/${DATASET}_testspace/exp1.csv >> $HOME_PATH/${DATASET}_testspace/exp4.csv
sed -n -e "/^${FIX_W},/p" $HOME_PATH/${DATASET}_testspace/exp1.csv > tmp # the line starting with FIX_W
cut -d "," -f 3- tmp >> $HOME_PATH/${DATASET}_testspace/exp4.csv # without the first two columns
rm tmp

# delete percentage 9% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_9_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# delete percentage 19% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_19_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# delete percentage 29% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_29_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# delete percentage 39% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_39_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# delete percentage 49% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# delete percentage 59% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_59_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# delete percentage 69% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_69_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# delete percentage 79% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_79_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# delete percentage 89% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_89_10
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp4.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp4, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/delete percentage,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp4.csv
line=2
for dp in 0 9 19 29 39 49 59 69 79 89
do
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_W}) | bc )
  sed -i -e ${line}"s/^/${dp},${c},/" $HOME_PATH/${DATASET}_testspace/exp4.csv
  let line+=1
done

(cut -f 1 -d "," $HOME_PATH/${DATASET}_testspace/exp4.csv) > tmp1.csv
(cut -f 4 -d "," $HOME_PATH/${DATASET}_testspace/exp4.csv| paste -d, tmp1.csv -) > tmp2.csv
(cut -f 71 -d "," $HOME_PATH/${DATASET}_testspace/exp4.csv| paste -d, tmp2.csv -) > tmp3.csv
echo "param,M4(ns),M4-LSM(ns)" > $HOME_PATH/${DATASET}_testspace/exp4_res.csv
sed '1d' tmp3.csv >> $HOME_PATH/${DATASET}_testspace/exp4_res.csv
rm tmp1.csv
rm tmp2.csv
rm tmp3.csv

############################
# [EXP5] Varying delete time range
# (1) w: 1000
# (2) query range: totalRange
# (3) overlap percentage: 10%
# (4) delete percentage: 49%
# (5) delete time range: 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90% of chunk time interval, that is x%*totalRange/(pointNum/chunkSize)
############################
# O_10_D_49_30
for delete_range in 20 30 40 50 60 70 80 90
do
  workspace="O_10_D_49_${delete_range}"
  cd $HOME_PATH/${DATASET}_testspace
  mkdir ${workspace}
  cd ${workspace}

  # prepare IoTDB config properties
  $HOME_PATH/tool.sh system_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/system ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh data_dirs $HOME_PATH/dataSpace/${DATASET}_${workspace}/data ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh wal_dir $HOME_PATH/dataSpace/${DATASET}_${workspace}/wal ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh timestamp_precision ${TIMESTAMP_PRECISION} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh unseq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh seq_tsfile_size 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh avg_series_point_number_threshold ${IOTDB_CHUNK_POINT_SIZE} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compaction_strategy NO_COMPACTION ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh enable_unseq_compaction false ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh group_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh page_size_in_byte 1073741824 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_address 0.0.0.0 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh rpc_port 6667 ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh time_encoder ${TIME_ENCODING} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh compressor ${COMPRESSOR} ../../iotdb-engine-example.properties
  $HOME_PATH/tool.sh error_Param 50 ../../iotdb-engine-example.properties
  # properties for cpv
  $HOME_PATH/tool.sh enable_CPV true ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVtrue.properties
  # properties for moc
  $HOME_PATH/tool.sh enable_CPV false ../../iotdb-engine-example.properties
  cp ../../iotdb-engine-example.properties iotdb-engine-enableCPVfalse.properties

  # [write data]
  echo "Writing ${workspace}"
  cp iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  cd $HOME_PATH/iotdb-server-0.12.4/sbin
  ./start-server.sh /dev/null 2>&1 &
  sleep 10s
  # Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx VALUE_ENCODING
  java -jar $HOME_PATH/WriteData*.jar ${DEVICE} ${MEASUREMENT} ${DATA_TYPE} ${TIMESTAMP_PRECISION} ${TOTAL_TIME_RANGE} ${TOTAL_POINT_NUMBER} ${IOTDB_CHUNK_POINT_SIZE} $HOME_PATH/${DATASET}/${DATASET}-O_10 ${FIX_DELETE_PERCENTAGE} ${delete_range} 0 1 ${VALUE_ENCODING} ${hasHeader}
  sleep 5s
  ./stop-server.sh
  sleep 5s
  echo 3 | sudo tee /proc/sys/vm/drop_caches

  # [query data]
  echo "Querying ${workspace}"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}
  mkdir fix

  # echo "moc"
  # cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  # mkdir moc
  # cd moc
  # cp $HOME_PATH/ProcessResult.* .
  # cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  # $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} moc >> result_3.txt
  # java ProcessResult result_3.txt result_3.out ../sumResultMOC.csv

  echo "mac"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir mac
  cd mac
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVfalse.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} mac >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultMAC.csv

  echo "cpv"
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  mkdir cpv
  cd cpv
  cp $HOME_PATH/ProcessResult.* .
  cp ../../iotdb-engine-enableCPVtrue.properties $HOME_PATH/iotdb-server-0.12.4/conf/iotdb-engine.properties
  # Usage: ./query_experiment.sh device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  $HOME_PATH/query_experiment.sh ${DEVICE} ${MEASUREMENT} ${TIMESTAMP_PRECISION} ${DATA_MIN_TIME} ${DATA_MAX_TIME} ${FIX_QUERY_RANGE} ${FIX_W} cpv >> result_3.txt
  java ProcessResult result_3.txt result_3.out ../sumResultCPV.csv

  # unify results
  cd $HOME_PATH/${DATASET}_testspace/${workspace}/fix
  cp $HOME_PATH/SumResultUnify.* .
  # java SumResultUnify sumResultMOC.csv sumResultMAC.csv sumResultCPV.csv result.csv
  java SumResultUnify sumResultMAC.csv sumResultCPV.csv result.csv
done

# export results
# [EXP5]
# w: 100
# query range: totalRange
# overlap percentage: 10%
# delete percentage: 49%
# delete time range: 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90% of chunk time interval, that is x%*totalRange/(pointNum/chunkSize)

# delete time range 10% exp result (already done in exp4)
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_10
cd fix
cat result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv #带表头

# delete time range 20% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_20
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# delete time range 30% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_30
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# delete time range 40% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_40
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# delete time range 50% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_50
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# delete time range 60% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_60
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# delete time range 70% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_70
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# delete time range 80% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_80
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# delete time range 90% exp result
cd $HOME_PATH/${DATASET}_testspace/O_10_D_49_90
cd fix
sed -n '2,2p' result.csv >>$HOME_PATH/${DATASET}_testspace/exp5.csv

# add varied parameter value and the corresponding estimated chunks per interval for each line
# estimated chunks per interval = range/w/(totalRange/(pointNum/chunkSize))
# for exp4, range=totalRange, estimated chunks per interval=(pointNum/chunkSize)/w
sed -i -e 1's/^/delete time range,estimated chunks per interval,/' $HOME_PATH/${DATASET}_testspace/exp5.csv
line=2
for dr in 10 20 30 40 50 60 70 80 90
do
  c=$((echo scale=3 ; echo ${TOTAL_POINT_NUMBER}/${IOTDB_CHUNK_POINT_SIZE}/${FIX_W}) | bc )
  sed -i -e ${line}"s/^/${dr},${c},/" $HOME_PATH/${DATASET}_testspace/exp5.csv
  let line+=1
done

(cut -f 1 -d "," $HOME_PATH/${DATASET}_testspace/exp5.csv) > tmp1.csv
(cut -f 4 -d "," $HOME_PATH/${DATASET}_testspace/exp5.csv| paste -d, tmp1.csv -) > tmp2.csv
(cut -f 71 -d "," $HOME_PATH/${DATASET}_testspace/exp5.csv| paste -d, tmp2.csv -) > tmp3.csv
echo "param,M4(ns),M4-LSM(ns)" > $HOME_PATH/${DATASET}_testspace/exp5_res.csv
sed '1d' tmp3.csv >> $HOME_PATH/${DATASET}_testspace/exp5_res.csv
rm tmp1.csv
rm tmp2.csv
rm tmp3.csv

echo "ALL FINISHED!"
echo 3 |sudo tee /proc/sys/vm/drop_caches
free -m