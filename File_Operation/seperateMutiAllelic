from hmac import new
import re

def split_info(info_str, alt_count):
    info_fields = info_str.split(';')
    result = {}
    for field in info_fields:
        key, *values = field.split('=')
        if len(values) == 1:
            value = values[0]
            if '|' in value:
                sub_values = value.split('|')
                if len(sub_values) == alt_count + 1:
                    result[key] = [f"{sub_values[0]}|{sub_values[i+1]}" for i in range(alt_count)]
                elif len(sub_values) == alt_count:
                    result[key] = sub_values
                else:
                    result[key] = [value] * alt_count
            elif ',' in value:
                sub_values = value.split(',')
                if len(sub_values) == alt_count + 1:
                    result[key] = [f"{sub_values[0]},{sub_values[i+1]}" for i in range(alt_count)]
                elif len(sub_values) == alt_count:
                    result[key] = sub_values
                else:
                    result[key] = [value] * alt_count
            else:
                result[key] = [value] * alt_count
        else:
            result[key] = [''] * alt_count
    return result

def split_sample_data(sample_data, format_keys, alt_count):
    sample_fields = sample_data.split(':')
    result = []
    for i in range(alt_count):
        new_sample_fields = []
        for key, value in zip(format_keys, sample_fields):
            if ',' in value:
                sub_values = value.split(',')
                if len(sub_values) == alt_count + 1:
                    new_value = f"{sub_values[0]},{sub_values[i+1]}"
                elif len(sub_values) == alt_count:
                    new_value = sub_values[i]
                else:
                    new_value = value
            elif '/' in value:
                sub_values = value.split('/')
                new_value = f"{sub_values[0]}|{sub_values[1]}"        
            else:
                new_value = value
            new_sample_fields.append(new_value)
        result.append(':'.join(new_sample_fields))
    return result

def process_vcf_line(line):
    fields = line.strip().split('\t')
    chrom, pos, id_, ref, alts, qual, filter_, info, format_, *samples = fields
    alt_list = alts.split(',')
    alt_count = len(alt_list)
    
    if alt_count == 1:
        return [line.strip()]  # 不进行任何更改
    
    info_dict = split_info(info, alt_count)
    format_keys = format_.split(':')
    
    new_lines = []
    for i, alt in enumerate(alt_list):
        new_info_parts = []
        for key in info_dict:
            new_info_parts.append(f"{key}={info_dict[key][i]}")
        new_info = ';'.join(new_info_parts)
        
        new_samples = split_sample_data(samples[0], format_keys, alt_count)
        
        new_line = '\t'.join([chrom, pos, id_, ref, alt, qual, filter_, new_info, format_, new_samples[i]])
        new_lines.append(new_line)
    
    return new_lines

def process_vcf(inputVCF, outputVCF):
    with open(inputVCF, 'r') as infile, open(outputVCF, 'w') as outfile:
        for line in infile:
            if line.startswith('#'):
                outfile.write(line)
            else:
                new_lines = process_vcf_line(line)
                for new_line in new_lines:
                    outfile.write(new_line + '\n')

# 输入输出文件路径
inputVCF = "C:\\Users\\Lenovo\\Desktop\\RA202009080240.1217.vcf"
outputVCF = "C:\\Users\\Lenovo\\Desktop\\RA202009080240.1217.only.vcf"

# 调用函数处理VCF文件
process_vcf(inputVCF, outputVCF)
