import os
import re
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import math # 用于处理 NaN

# --- 配置 ---
base_result_dir = '$T1_HOME/result'  # 你的结果根目录
output_dir = 'analysis_plots' # 图表输出目录
benchmarks = ['gemm', 'linpack', 'mcf', 'stream', 'tcc', 'whetstone', 'x264']
components = ['frontend', 'execution', 'memory', 'cache', 'branch']
# 注意：假设 '' 代表 ideal/baseline (即 'benchmark-' 目录)
levels = ['', '_L0', '_L1', '_L2']
level_labels = ['Ideal/Base', 'L0', 'L1', 'L2'] # 用于图表标签

# 定义要提取和绘图的指标 (key: 图表文件名和标题中使用的名称, value: stats.txt中的统计信息名称 或 计算元组)
# 你可以根据需要添加更多指标
metrics_to_extract = {
    # Overall
    'IPC': 'system.cpu.ipc',
    'Cycles': 'system.cpu.numCycles',
    # Frontend
    'Frontend_Bound_Pct': 'system.cpu.frontendBound',
    'Fetch_Rate': 'system.cpu.fetch.rate',
    # Execution
    'Core_Bound_Pct': 'system.cpu.coreBound',
    'Issue_Rate': 'system.cpu.iq.issueRate',
    'IQ_Full_Stalls': 'system.cpu.iew.stallEvents::IQFull',
    'ROB_Full_Stalls': 'system.cpu.iew.stallEvents::ROBFull',
    # Memory
    'Memory_Bound_Pct': 'system.cpu.memoryBound',
    'L1D_Miss_Rate_Pct': 'system.cpu.dcache.overallMissRate::total',
    'L1D_Avg_Miss_Latency': 'system.cpu.dcache.overallAvgMissLatency::total',
    'LSQ_Full_Stalls': 'system.cpu.iew.stallEvents::LSQFull',
    'SBuf_Full_Cycles': 'system.cpu.lsq0.sbufferFull',
    # Cache
    'L1D_Bound_Pct': 'system.cpu.l1Bound',
    'L2_Bound_Pct': 'system.cpu.l2Bound',
    'L3_Bound_Pct': 'system.cpu.l3Bound',
    'L2_Miss_Rate_Pct': 'system.l2_caches.overallMissRate::total',
    'L3_Miss_Rate_Pct': 'system.l3.overallMissRate::total',
    # Branch
    'BP_Mispred_Pct': ('system.cpu.commit.branchMispredicts', 'system.cpu.commit.branches'),
    'Frontend_Latency_Bound_Pct': 'system.cpu.frontendLatencyBound',
    'Bad_Spec_Bound_Pct': 'system.cpu.badSpecBound',
    'Branch_Mispred_Bound_Pct': 'system.cpu.branchMissPrediction',
    'FTB_Miss_Rate_Pct': ('system.cpu.branchPred.ftbMiss', ('system.cpu.branchPred.ftbHit', 'system.cpu.branchPred.ftbMiss')),
    'Cond_Miss_Rate_Pct': ('system.cpu.branchPred.condMiss', 'system.cpu.branchPred.condNum'),
}

# --- 辅助函数 ---

def extract_stats(stats_file, metrics):
    """从 stats.txt 文件中提取指定的指标"""
    results = {}
    # 初始化所有指标为 NaN
    for key in metrics.keys():
        results[key] = np.nan

    if not os.path.exists(stats_file):
        print(f"警告: 文件未找到 {stats_file}")
        return results

    try:
        with open(stats_file, 'r') as f:
            lines = f.readlines()

        for key, stat_name_or_tuple in metrics.items():
            raw_stat_names = []
            is_calculated = isinstance(stat_name_or_tuple, tuple)

            if is_calculated:
                raw_stat_names.extend([s for s in stat_name_or_tuple if isinstance(s, str)])
                for item in stat_name_or_tuple:
                    if isinstance(item, tuple):
                        raw_stat_names.extend([s for s in item if isinstance(s, str)])
            else:
                raw_stat_names.append(stat_name_or_tuple)

            stat_values = {}
            all_necessary_found = True
            for stat_name in set(raw_stat_names):
                pattern = re.compile(r"^\s*" + re.escape(stat_name) + r"\s+([\d\.nan\-inf]+)\s*.*$")
                found = False
                for line in lines:
                    match = pattern.match(line)
                    if match:
                        try:
                            val_str = match.group(1).lower()
                            if val_str == 'nan':
                                stat_values[stat_name] = np.nan
                            elif val_str == 'inf' or val_str == '-inf':
                                stat_values[stat_name] = np.inf if val_str == 'inf' else -np.inf
                            else:
                                stat_values[stat_name] = float(val_str)
                            found = True
                            break
                        except ValueError:
                            print(f"警告: 无法解析值 '{match.group(1)}' 对于指标 {stat_name} 在文件 {stats_file}")
                            stat_values[stat_name] = np.nan
                            found = True
                            break
                if not found:
                    # print(f"警告: 指标 '{stat_name}' 未在文件 {stats_file} 中找到")
                    stat_values[stat_name] = np.nan
                    if is_calculated: # 如果是计算指标，任何一个原始数据找不到都算失败
                         all_necessary_found = False


            # 只有当所有 *必要的* 原始数据都找到时才进行计算或赋值
            if not is_calculated and stat_name_or_tuple in stat_values:
                 results[key] = stat_values[stat_name_or_tuple]
            elif is_calculated and all_necessary_found:
                 # --- 执行计算 ---
                if key == 'BP_Mispred_Pct':
                    mispreds = stat_values.get(stat_name_or_tuple[0], np.nan)
                    total_branches = stat_values.get(stat_name_or_tuple[1], np.nan)
                    results[key] = (mispreds / total_branches * 100) if total_branches > 0 and not (math.isnan(mispreds) or math.isnan(total_branches)) else np.nan
                elif key == 'FTB_Miss_Rate_Pct':
                    misses = stat_values.get(stat_name_or_tuple[0], np.nan)
                    hits = stat_values.get(stat_name_or_tuple[1][0], np.nan)
                    misses_denom = stat_values.get(stat_name_or_tuple[1][1], np.nan)
                    total = hits + misses_denom if not (math.isnan(hits) or math.isnan(misses_denom)) else np.nan
                    results[key] = (misses / total * 100) if total > 0 and not (math.isnan(misses) or math.isnan(total)) else np.nan
                elif key == 'Cond_Miss_Rate_Pct':
                    misses = stat_values.get(stat_name_or_tuple[0], np.nan)
                    total = stat_values.get(stat_name_or_tuple[1], np.nan)
                    results[key] = (misses / total * 100) if total > 0 and not (math.isnan(misses) or math.isnan(total)) else np.nan
                # --- 为其他需要计算的指标添加 elif ---
            # else: # 保持为 NaN

            # 如果是百分比指标（名称包含 Pct），乘以 100
            # (确保只对成功获取/计算的值操作, 并且不是已经计算好的百分比)
            if 'Pct' in key and key not in ['BP_Mispred_Pct', 'FTB_Miss_Rate_Pct', 'Cond_Miss_Rate_Pct']:
                if not math.isnan(results[key]):
                     results[key] *= 100

    except FileNotFoundError:
        # print(f"错误: 文件未找到 {stats_file}") # 已经在函数开始时处理
        pass
    except Exception as e:
        print(f"错误: 处理文件 {stats_file} 时出错: {e}")

    return results

# --- 保留原有的绘图函数 ---
def plot_bars(data_df, metric_key, component, output_dir):
    """为单个指标和部件生成分组柱状图 (所有 benchmarks)"""
    metric_label = metric_key.replace('_', ' ')

    if metric_key not in data_df.columns:
        print(f"警告: 指标 '{metric_key}' 不在为组件 '{component}' 收集的数据中。跳过聚合绘图。")
        return

    try:
        pivot_df = data_df.pivot(index='Benchmark', columns='Level', values=metric_key)
        pivot_df = pivot_df.reindex(columns=level_labels) # 删除 axis=1
    except Exception as e:
        print(f"错误: 为聚合指标 '{metric_key}' 和组件 '{component}' 重塑数据时出错: {e}")
        return

    if pivot_df.empty or not all(col in pivot_df.columns for col in level_labels):
         print(f"警告: 聚合 Pivot 或 Reindex 后数据为空或缺少列，指标: '{metric_key}', 组件: '{component}'. 跳过绘图。")
         return

    ax = pivot_df.plot(kind='bar', figsize=(15, 7), width=0.8)
    plt.title(f'{metric_label} Sensitivity (All Benchmarks) - {component.capitalize()} Test')
    plt.ylabel(metric_label)
    plt.xlabel('Benchmark')
    plt.xticks(rotation=45, ha='right')
    plt.legend(title='Config Level')
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()

    plot_filename = f'ALL_BENCH_{metric_key}__{component}.png' # 添加前缀区分
    plot_path = os.path.join(output_dir, component, plot_filename)
    try:
        plt.savefig(plot_path)
        print(f"聚合图表已保存: {plot_path}")
    except Exception as e:
        print(f"错误: 保存聚合图表 {plot_path} 时出错: {e}")
    plt.close()

# --- 新增的绘图函数 ---
def plot_bars_per_benchmark(benchmark_df, benchmark_name, metric_key, component, output_dir):
    """为单个 benchmark 的单个指标和部件生成柱状图"""
    metric_label = metric_key.replace('_', ' ')

    if metric_key not in benchmark_df.columns:
        print(f"警告: 指标 '{metric_key}' 不在为组件 '{component}', Benchmark '{benchmark_name}' 收集的数据中。跳过绘图。")
        return

    # 准备单个 benchmark 的数据
    try:
        # 设置 Level 为索引，选择指标列，确保顺序正确
        plot_data = benchmark_df.set_index('Level')[metric_key].reindex(level_labels)
        if plot_data.isnull().all(): # 检查是否所有值都是 NaN
            print(f"警告: 指标 '{metric_key}' 的所有数据均为 NaN，Benchmark: '{benchmark_name}', 组件: '{component}'. 跳过绘图。")
            return
    except KeyError: # 如果 Level 列不存在或 metric_key 不存在
        print(f"警告: 无法设置索引或选择指标 '{metric_key}'，Benchmark: '{benchmark_name}', 组件: '{component}'. 跳过绘图。")
        return
    except Exception as e:
        print(f"错误: 为 Benchmark 特定指标 '{metric_key}' 和组件 '{component}' 准备数据时出错: {e}")
        print("DataFrame 内容:")
        print(benchmark_df)
        return

    # 绘图
    ax = plot_data.plot(kind='bar', figsize=(8, 6), width=0.6) # 可以用稍小尺寸

    plt.title(f'{metric_label} - {benchmark_name} - {component.capitalize()} Test')
    plt.ylabel(metric_label)
    plt.xlabel('Configuration Level') # X轴现在是配置级别
    plt.xticks(rotation=0) # 标签不需要旋转
    # 单个 benchmark 不需要图例
    if ax.get_legend() is not None:
        ax.get_legend().remove()
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.tight_layout()

    # 保存图表
    plot_filename = f'{benchmark_name}__{metric_key}__{component}.png' # 文件名包含 benchmark
    plot_path = os.path.join(output_dir, component, benchmark_name, plot_filename)
    try:
        plt.savefig(plot_path)
        print(f"Benchmark 特定图表已保存: {plot_path}")
    except Exception as e:
        print(f"错误: 保存 Benchmark 特定图表 {plot_path} 时出错: {e}")
    plt.close() # 关闭图表以释放内存

# --- 主逻辑 ---

# 创建输出目录
os.makedirs(output_dir, exist_ok=True)
for comp in components:
    os.makedirs(os.path.join(output_dir, comp), exist_ok=True)
    for benchmark in benchmarks:
        os.makedirs(os.path.join(output_dir, comp, benchmark), exist_ok=True)

all_data = {} # 存储所有组件的数据

# 收集数据 (与之前相同)
print("开始收集数据...")
for component in components:
    component_data = []
    print(f"处理组件: {component}")
    for benchmark in benchmarks:
        print(f"  处理 Benchmark: {benchmark}")
        for i, level_suffix in enumerate(levels):
            level_label = level_labels[i]
            if level_suffix == '':
                run_name = f"{benchmark}-" # 基准/Ideal 运行
            else:
                run_name = f"{benchmark}-{component}{level_suffix}"
            stats_path = os.path.join(base_result_dir, benchmark, run_name, 'stats.txt')

            stats = extract_stats(stats_path, metrics_to_extract)

            row = {'Benchmark': benchmark, 'Level': level_label, 'Component': component}
            row.update(stats)
            component_data.append(row)

    if component_data:
        all_data[component] = pd.DataFrame(component_data)
        print(f"组件 {component} 的数据收集完成.")
    else:
        print(f"警告: 组件 {component} 没有收集到数据.")

print("数据收集完毕.")

# --- 生成聚合图表 (所有 benchmarks 在一张图上) ---
print("\n开始生成聚合图表 (每个指标一张图)...")
for component, df in all_data.items():
    if df is None or df.empty:
        print(f"跳过组件 {component} 的聚合绘图，因为没有数据.")
        continue
    print(f"为组件 {component} 生成聚合图表...")
    for metric in metrics_to_extract.keys():
        plot_bars(df.copy(), metric, component, output_dir) # 传入 DataFrame 的副本以防修改

# --- 生成 Benchmark 特定图表 (每个 benchmark 一张图) ---
print("\n开始生成 Benchmark 特定图表...")
for component, df in all_data.items():
    if df is None or df.empty:
        print(f"跳过组件 {component} 的 Benchmark 特定绘图，因为没有数据.")
        continue
    print(f"为组件 {component} 生成 Benchmark 特定图表...")
    # 获取该组件数据中实际存在的所有 benchmark
    benchmarks_in_data = df['Benchmark'].unique()
    for benchmark in benchmarks_in_data:
        print(f"  处理 Benchmark: {benchmark}")
        # 筛选出当前 benchmark 的数据
        benchmark_df = df[df['Benchmark'] == benchmark].copy()
        if benchmark_df.empty:
            print(f"    警告: Benchmark '{benchmark}' 在组件 '{component}' 数据中没有条目。")
            continue
        for metric in metrics_to_extract.keys():
            # 调用新的绘图函数
            plot_bars_per_benchmark(benchmark_df, benchmark, metric, component, output_dir)

print("所有图表生成完毕.")
