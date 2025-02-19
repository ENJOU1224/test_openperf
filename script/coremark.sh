cd $T1_HOME
# prepare the binary file
git clone https://github.com/OpenXiangShan/ready-to-run.git
# run the workload
$GEM5_HOME/build/RISCV/gem5.opt $GEM5_HOME/configs/example/xiangshan.py --raw-cpt --generic-rv-cpt=$T1_HOME/ready-to-run/coremark-2-iteration.bin
