cd $T1_HOME
# prepare the binary file
git clone https://github.com/OpenXiangShan/ready-to-run.git --filter=tree:0
# run the workload
$GEM5/build/RISCV/gem5.opt $GEM5/configs/example/xiangshan.py --raw-cpt --generic-rv-cpt=$T1_HOME/ready-to-run/coremark-2-iteration.bin
