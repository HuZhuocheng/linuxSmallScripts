library(dplyr)
library(tidyr)
library(stringr)

lines <- readLines("C:\\Users\\Lenovo\\Desktop\\0108.vcf")
header_index <- grep("^#", lines)
header_index <- header_index[!grepl("^##", lines[header_index])][1] 
header_line <- lines[header_index]
data_lines <- lines[(header_index + 1):length(lines)]
col_names <- unlist(strsplit(header_line, "\t"))
vcf_data <- read.table(text = data_lines, header = FALSE, col.names = col_names, stringsAsFactors = FALSE)

# 处理FORMAT列及其对应的样本列
format_sample_pairs <- lapply(seq_along(vcf_data$FORMAT), function(i) {
  format_fields <- unlist(strsplit(vcf_data$FORMAT[i], ":"))
  sample_values <- unlist(strsplit(vcf_data[[ncol(vcf_data)]][i], ":"))
  
  # 检查是否分割正确
  if (length(format_fields) != length(sample_values)) {
    cat("行号:", i, " - 格式字段长度:", length(format_fields), " - 样本值长度:", length(sample_values), "\n")
    cat("格式字段:", format_fields, "\n")
    cat("样本值:", sample_values, "\n")
  }
  
  setNames(sample_values, format_fields)
})
# 获取所有可能的格式字段
all_format_keys <- unique(unlist(lapply(format_sample_pairs, names)))
# 创建一个模板数据框
template_format_df <- data.frame(matrix(NA, nrow = length(format_sample_pairs), ncol = length(all_format_keys)))
colnames(template_format_df) <- all_format_keys
for (i in seq_along(format_sample_pairs)) {
  template_format_df[i, names(format_sample_pairs[[i]])] <- unlist(format_sample_pairs[[i]])
}
vcf_data <- cbind(vcf_data, template_format_df)

# 处理INFO列，将其拆分为多个列
info_list <- vcf_data$INFO %>%
  strsplit(split = ";") 
all_keys <- unique(unlist(lapply(info_list, function(x) sapply(strsplit(x, "="), "[[", 1))))
template_df <- data.frame(matrix(NA, nrow = length(info_list), ncol = length(all_keys)))
colnames(template_df) <- all_keys  
for (i in seq_along(info_list)) {
  info_pairs <- strsplit(info_list[[i]], "=")
  for (pair in info_pairs) {
    key <- pair[1]
    value <- ifelse(length(pair) > 1, pair[2], NA)
    template_df[i, key] <- value
  }
}
vcf_data <- cbind(vcf_data, template_df)
all_values <- unlist(strsplit(as.character(vcf_data$FILTER), split=";"))
unique_values <- unique(all_values)
print(unique_values)

#########重命名DP列
dp_indices <- which(names(vcf_data) == "DP")
if (length(dp_indices) > 1) {
  vcf_data <- vcf_data %>%
    rename_with(~ "FORMAT_DP", .cols = dp_indices[2])
}

names(vcf_data)[1] <- "#CHROM"

write.table(vcf_data, "C:\\Users\\Lenovo\\Desktop\\0108_Sep.vcf", row.names = FALSE, sep = "\t", quote = FALSE)







vcf_filter <- vcf_data %>% 
  mutate(AD_split = strsplit(as.character(AD),',')) %>% 
  mutate(AD_ref = as.integer(sapply(AD_split, `[`, 1)),
         AD_alt = as.integer(sapply(AD_split, `[`, 2))) %>% 
  select(-AD_split) %>% 
  mutate(FORMAT_DP = as.integer(FORMAT_DP)) %>% 
  mutate(AF_alt = AD_alt / FORMAT_DP) %>% 
  mutate(my_FILTER = "") %>%
  mutate(my_FILTER = ifelse((AF_alt > 0.01) & (AD_alt > 5), 
                            "Pass_Initial", "Fail_Initial")) %>%
  mutate(my_FILTER = ifelse((FORMAT_DP > 200) & (AD_alt > 8) & (AF >= 0.02), 
                            "Pass_Preliminary", my_FILTER)) %>% 
  mutate(my_FILTER = ifelse((FORMAT_DP >= 200) & (AD_alt >= 10) & (AF >= 0.05), 
                            "Pass_Secondary", my_FILTER))
vcf_filter_test <- vcf_filter[,c('my_FILTER','AF_alt','FORMAT_DP','AF','AD_ref','AD_alt')]
  
  
  
