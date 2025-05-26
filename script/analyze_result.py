#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import math

# --- Matplotlib 配置 (使用默认英文字体) ---
plt.rcParams['axes.unicode_minus'] = False

# --- 用户配置区域 ---
# base_result_dir 在 main 函数中通过环境变量 T1_HOME 定义
output_dir = 'analysis_plots' # 图表输出目录
benchmarks = ['gemm', 'linpack', 'mcf', 'stream', 'tcc', 'whetstone', 'x264']
components = ['frontend', 'execution', 'memory', 'cache', 'branch', 'branch_bandwidth']

level_configs = {
    'default': 'Ideal/Base',
    '_L0': 'L0',
    '_L1': 'L1',
    '_L2': 'L2'
}
plot_level_order = ['Ideal/Base', 'L0', 'L1', 'L2']

metrics_to_extract = {
    'IPC': 'system.cpu.ipc', 'Cycles': 'system.cpu.numCycles',
    'Frontend_Bound_Pct': 'system.cpu.frontendBound',
    'Frontend_Latency_Bound_Pct': 'system.cpu.frontendLatencyBound',
    'Frontend_Bandwidth_Bound_Pct': 'system.cpu.frontendBandwidthBound',
    'Bad_Spec_Bound_Pct': 'system.cpu.badSpecBound',
    'Branch_Mispred_Bound_Pct_Stall': 'system.cpu.branchMissPrediction',
    'Machine_Clears_Bound_Pct': 'system.cpu.machineClears',
    'Backend_Bound_Pct': 'system.cpu.backendBound',
    'Core_Bound_Pct': 'system.cpu.coreBound', 'Memory_Bound_Pct': 'system.cpu.memoryBound',
    'L1_Bound_Pct': 'system.cpu.l1Bound', 'L2_Bound_Pct': 'system.cpu.l2Bound',
    'L3_Bound_Pct': 'system.cpu.l3Bound', 'Mem_Bound_Pct': 'system.cpu.memBound',
    'Store_Bound_Pct': 'system.cpu.storeBound', 'Fetch_Rate': 'system.cpu.fetch.rate',
    'Issue_Rate': 'system.cpu.iq.issueRate',
    'IQ_Full_Stalls': 'system.cpu.iew.stallEvents::IQFull',
    'L1D_Miss_Rate_Pct': 'system.cpu.dcache.overallMissRate::total',
    'L1D_Avg_Miss_Latency': 'system.cpu.dcache.overallAvgMissLatency::total',
    'LSQ_Full_Stalls': 'system.cpu.iew.stallEvents::LSQFull',
    'SBuf_Full_Cycles': 'system.cpu.lsq0.sbufferFull',
    'L2_Miss_Rate_Pct': 'system.l2_caches.overallMissRate::total',
    'L3_Miss_Rate_Pct': 'system.l3.overallMissRate::total',
    'BP_Mispred_Pct': ('system.cpu.commit.branchMispredicts', 'system.cpu.commit.branches'),
    'FTB_Miss_Rate_Pct': ('system.cpu.branchPred.ftbMiss', ('system.cpu.branchPred.ftbHit', 'system.cpu.branchPred.ftbMiss')),
    'Cond_Miss_Rate_Pct': ('system.cpu.branchPred.condMiss', 'system.cpu.branchPred.condNum'),
    'FSQ_Full_Cannot_Enqueue': 'system.cpu.branchPred.fsqFullCannotEnq',
    'FSQ_Full_Fetch_Hungry': 'system.cpu.branchPred.fsqFullFetchHungry',
    'Committed_Branches': 'system.cpu.commit.branches',
}

# --- 辅助函数 (与上一版相同) ---
def get_stat_value(stat_name, lines, stats_file_path):
    pattern = re.compile(r"^\s*" + re.escape(stat_name) + r"\s+([\d\.nan\-inf]+)\s*.*$")
    for line in lines:
        match = pattern.match(line)
        if match:
            try:
                val_str = match.group(1).lower()
                if val_str == 'nan': return np.nan
                if val_str == 'inf': return np.inf
                if val_str == '-inf': return -np.inf
                return float(val_str)
            except ValueError: return np.nan
    return np.nan

def _get_all_raw_stat_names_from_tuple(item_tuple, name_set):
    for item in item_tuple:
        if isinstance(item, str): name_set.add(item)
        elif isinstance(item, tuple): _get_all_raw_stat_names_from_tuple(item, name_set)

def calculate_metric(metric_key, calculation_tuple, stat_values_dict):
    try:
        if metric_key == 'BP_Mispred_Pct':
            n, d = stat_values_dict.get(calculation_tuple[0]), stat_values_dict.get(calculation_tuple[1])
            if pd.notna(n) and pd.notna(d) and d > 0: return (n / d) * 100
        elif metric_key == 'FTB_Miss_Rate_Pct':
            m, h, md = stat_values_dict.get(calculation_tuple[0]), stat_values_dict.get(calculation_tuple[1][0]), stat_values_dict.get(calculation_tuple[1][1])
            if pd.notna(m) and pd.notna(h) and pd.notna(md):
                t = h + md
                if t > 0: return (m / t) * 100
        elif metric_key == 'Cond_Miss_Rate_Pct':
            n, d = stat_values_dict.get(calculation_tuple[0]), stat_values_dict.get(calculation_tuple[1])
            if pd.notna(n) and pd.notna(d) and d > 0: return (n / d) * 100
    except Exception: pass
    return np.nan

def extract_stats(stats_file_path, metrics_config):
    results = {key: np.nan for key in metrics_config.keys()}
    if not os.path.exists(stats_file_path): return results
    try:
        with open(stats_file_path, 'r', encoding='utf-8') as f: lines = f.readlines()
    except Exception as e:
        print(f"错误: 读取文件 {stats_file_path} 时出错: {e}")
        return results

    raw_vals, raw_names = {}, set()
    for k, v_or_t in metrics_config.items():
        if isinstance(v_or_t, str): raw_names.add(v_or_t)
        elif isinstance(v_or_t, tuple): _get_all_raw_stat_names_from_tuple(v_or_t, raw_names)
    for name in raw_names: raw_vals[name] = get_stat_value(name, lines, stats_file_path)

    for k, v_or_t in metrics_config.items():
        if isinstance(v_or_t, str):
            results[k] = raw_vals.get(v_or_t, np.nan)
            if 'Pct' in k and pd.notna(results[k]): results[k] *= 100
        elif isinstance(v_or_t, tuple):
            results[k] = calculate_metric(k, v_or_t, raw_vals)
    return results

# --- 绘图函数 (增加 emoji 状态提示) ---
def plot_bars_all_benchmarks(data_df, metric_key, component_name, base_output_dir):
    """(聚合图) 为单个指标和组件生成分组柱状图 - 增加 emoji 状态"""
    metric_label_en = metric_key.replace('_Pct', ' (%)').replace('_', ' ')
    plot_subdir = os.path.join(base_output_dir, component_name, "_all_benchmarks_summary")
    os.makedirs(plot_subdir, exist_ok=True)
    plot_filename = f'{metric_key}_all_benchmarks_{component_name}.png'
    plot_path = os.path.join(plot_subdir, plot_filename)

    # print(f"    正在生成聚合图: {plot_filename}") # 可以取消注释这个来获得更详细的“正在生成”提示

    if metric_key not in data_df.columns:
        print(f"  ❌ 跳过聚合图 (指标缺失): {plot_filename}")
        return
    try:
        data_df['Level'] = pd.Categorical(data_df['Level'], categories=plot_level_order, ordered=True)
        pivot_df = pd.pivot_table(data_df, values=metric_key, index='Benchmark', columns='Level', aggfunc='mean', observed=False)
        cols_to_plot = [col for col in plot_level_order if col in pivot_df.columns]
        if not cols_to_plot:
            print(f"  ❌ 跳过聚合图 (无有效级别数据): {plot_filename}")
            return
        pivot_df = pivot_df[cols_to_plot]
    except Exception as e:
        print(f"  ❌ 跳过聚合图 (数据处理错误: {e}): {plot_filename}")
        return
    if pivot_df.empty or pivot_df.isnull().all().all():
        print(f"  ❌ 跳过聚合图 (数据为空或全NaN): {plot_filename}")
        return

    try: # 将绘图和保存都放在 try 块中
        ax = pivot_df.plot(kind='bar', figsize=(17, 8), width=0.85, colormap='viridis', edgecolor='grey')
        plt.title(f'{metric_label_en} - All Benchmarks - {component_name.capitalize()} Bottleneck Test', fontsize=16, pad=20)
        plt.ylabel(metric_label_en, fontsize=13); plt.xlabel('Benchmark', fontsize=13)
        plt.xticks(rotation=30, ha='right', fontsize=10); plt.yticks(fontsize=10)
        plt.legend(title='Config Level', fontsize=10, title_fontsize=11)
        plt.grid(axis='y', linestyle='--', alpha=0.6); ax.spines['top'].set_visible(False); ax.spines['right'].set_visible(False)
        plt.tight_layout(pad=1.5)
        plt.savefig(plot_path, dpi=150, bbox_inches='tight')
        print(f"  ✅ 聚合图已生成: {plot_filename}")
    except Exception as e:
        print(f"  ❌ 生成聚合图失败 {plot_filename}: {e}")
    finally: # 确保总是关闭 plt 对象
        plt.close()

def plot_bars_per_benchmark(benchmark_data_df, benchmark_name, metric_key, component_name, base_output_dir):
    """(Benchmark特定图) 为单个 benchmark 的单个指标和部件生成柱状图 - 增加 emoji 状态"""
    metric_label_en = metric_key.replace('_Pct', ' (%)').replace('_', ' ')
    plot_subdir = os.path.join(base_output_dir, component_name, benchmark_name)
    os.makedirs(plot_subdir, exist_ok=True)
    plot_filename = f'{benchmark_name}_{metric_key}_{component_name}.png'
    plot_path = os.path.join(plot_subdir, plot_filename)

    # print(f"      正在生成图: {plot_filename}") # 可以取消注释

    if metric_key not in benchmark_data_df.columns:
        print(f"    ❌ 跳过图 (指标缺失): {plot_filename}")
        return

    benchmark_data_df['Level'] = pd.Categorical(benchmark_data_df['Level'], categories=plot_level_order, ordered=True)
    plot_data = benchmark_data_df.set_index('Level').sort_index()[metric_key]
    if plot_data.isnull().all():
        print(f"    ⚠️  跳过图 (数据全为NaN): {plot_filename} (指标 '{metric_key}', Benchmark: '{benchmark_name}', 组件: '{component_name}')")
        return

    try: # 将绘图和保存都放在 try 块中
        ax = plot_data.plot(kind='bar', figsize=(9, 6), width=0.65, color='steelblue', edgecolor='grey')
        plt.title(f'{metric_label_en}\n{benchmark_name.upper()} - {component_name.capitalize()} Bottleneck Test', fontsize=14, pad=15)
        plt.ylabel(metric_label_en, fontsize=12); plt.xlabel('Configuration Level', fontsize=12)
        plt.xticks(rotation=0, fontsize=10); plt.yticks(fontsize=10)
        if ax.get_legend() is not None: ax.get_legend().remove()
        plt.grid(axis='y', linestyle='--', alpha=0.6); ax.spines['top'].set_visible(False); ax.spines['right'].set_visible(False)
        plt.tight_layout(pad=1.5)
        plt.savefig(plot_path, dpi=150, bbox_inches='tight')
        print(f"      ✅ 图已生成: {plot_filename}")
    except Exception as e:
        print(f"    ❌ 生成图失败 {plot_filename}: {e}")
    finally: # 确保总是关闭 plt 对象
        plt.close()

# --- 主逻辑 ---
def main():
    t1_home_path = os.getenv('T1_HOME')
    if not t1_home_path:
        print("错误: 环境变量 T1_HOME 未设置。请设置 T1_HOME 指向您的项目根目录。")
        exit(1)
    
    global base_result_dir
    base_result_dir = os.path.join(t1_home_path, 'result')

    print(f"图表将输出到: {output_dir}")
    if not os.path.isdir(base_result_dir):
        print(f"错误: 结果根目录未找到: {base_result_dir}")
        exit(1)
    os.makedirs(output_dir, exist_ok=True)

    all_component_data_frames = {}
    print("\n--- 开始收集数据 ---")
    for comp_name_iter in components:
        print(f"处理组件: {comp_name_iter.capitalize()}")
        current_component_data_list = []
        os.makedirs(os.path.join(output_dir, comp_name_iter), exist_ok=True)

        for bench_name_iter in benchmarks:
            os.makedirs(os.path.join(output_dir, comp_name_iter, bench_name_iter), exist_ok=True)
            ideal_run_name = f"{bench_name_iter}-default"
            ideal_stats_path = os.path.join(base_result_dir, bench_name_iter, ideal_run_name, 'stats.txt')
            if not os.path.exists(ideal_stats_path): print(f"  警告: 文件未找到 (基准 {bench_name_iter}, Ideal/Base): {ideal_stats_path}")
            ideal_stats = extract_stats(ideal_stats_path, metrics_to_extract)
            row_ideal = {'Benchmark': bench_name_iter, 'Level': level_configs['default'], 'Component': comp_name_iter}
            row_ideal.update(ideal_stats); current_component_data_list.append(row_ideal)

            for level_suffix_key, level_label_val in level_configs.items():
                if level_suffix_key == 'default': continue
                param_run_name = f"{bench_name_iter}-{comp_name_iter}{level_suffix_key}"
                param_stats_path = os.path.join(base_result_dir, bench_name_iter, param_run_name, 'stats.txt')
                if not os.path.exists(param_stats_path): print(f"  警告: 文件未找到 (基准 {bench_name_iter}, 参数 {comp_name_iter}{level_suffix_key}): {param_stats_path}")
                param_stats = extract_stats(param_stats_path, metrics_to_extract)
                row_param = {'Benchmark': bench_name_iter, 'Level': level_label_val, 'Component': comp_name_iter}
                row_param.update(param_stats); current_component_data_list.append(row_param)
        
        if current_component_data_list:
            comp_df = pd.DataFrame(current_component_data_list)
            metric_cols = [col for col in comp_df.columns if col not in ['Benchmark', 'Level', 'Component']]
            comp_df.dropna(subset=metric_cols, how='all', inplace=True)
            if not comp_df.empty: all_component_data_frames[comp_name_iter] = comp_df
            else: print(f"警告: 组件 {comp_name_iter.capitalize()} 清理后没有有效数据。")
        else: print(f"警告: 组件 {comp_name_iter.capitalize()} 没有收集到任何数据。")
    print("--- 数据收集完毕 ---")

    if not all_component_data_frames:
        print("错误: 未收集到任何组件的有效数据。程序退出。")
        return

    print("\n--- 开始生成图表 ---")
    total_plots_attempted = 0
    successful_plots = 0
    failed_plots = 0

    for comp_name_iter, current_comp_df in all_component_data_frames.items():
        if current_comp_df is None or current_comp_df.empty: continue
        
        print(f"\n为组件 {comp_name_iter.capitalize()} 生成图表:")
        
        # 1. 聚合图表
        for metric_key_iter in metrics_to_extract.keys():
            total_plots_attempted += 1
            # plot_bars_all_benchmarks 函数内部会打印 ✅ 或 ❌
            # 我们可以通过捕获返回值或修改函数来统计成功失败，但为了简单，先只依赖其打印
            plot_bars_all_benchmarks(current_comp_df.copy(), metric_key_iter, comp_name_iter, output_dir)
            # 假设如果 plot_bars_... 内部没有打印错误，就是成功的
            # 这是一个简化的计数，更精确的计数需要函数返回值或全局计数器

        # 2. Benchmark 特定图表
        unique_benchmarks_in_component_data = current_comp_df['Benchmark'].unique()
        for bench_name_iter in unique_benchmarks_in_component_data:
            print(f"  正在处理基准测试: {bench_name_iter} (组件: {comp_name_iter.capitalize()})")
            benchmark_specific_df_iter = current_comp_df[current_comp_df['Benchmark'] == bench_name_iter].copy()
            if benchmark_specific_df_iter.empty: continue
            
            for metric_key_iter in metrics_to_extract.keys():
                total_plots_attempted += 1
                plot_bars_per_benchmark(benchmark_specific_df_iter, bench_name_iter, metric_key_iter, comp_name_iter, output_dir)

        print(f"组件 {comp_name_iter.capitalize()} 的图表已处理。")


    # 成功/失败计数需要绘图函数能返回状态，或者在绘图函数内部更新全局计数器。
    # 为了保持绘图函数简洁，我们这里只报告尝试生成的总数。
    print(f"\n--- 所有图表处理完毕 (共尝试 {total_plots_attempted} 张)。请检查输出目录: {output_dir} ---")
    print("注意：请查看上面日志中是否有 ❌ 标记的生成失败的图表。")

if __name__ == '__main__':
    main()
