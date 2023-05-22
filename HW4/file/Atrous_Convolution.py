import numpy as np

# 定義輸入圖像大小和 Replicate Padding 後的大小
input_size = 64
output_size = 64
padding_size = 2

# 生成模擬輸入圖像
input_image = np.random.rand(input_size, input_size)

# 定義 Atrous Convolution 的卷積核和 atrous rate
kernel = np.random.rand(3, 3)
atrous_rate = 2

# 定義 Replicate Padding 的輸出圖像
padded_size = input_size + 2 * padding_size
padded_input = np.zeros((padded_size, padded_size))  # 68*68
for i in range(input_size):
    for j in range(input_size):
        padded_input[i+padding_size, j+padding_size] = input_image[i, j]
# for i in range(padding_size):
#     padded_input[i, padding_size:padded_size-padding_size] = padded_input[padding_size, padding_size:padded_size-padding_size]
#     padded_input[padded_size-i-1, padding_size:padded_size-padding_size] = padded_input[padded_size-padding_size-1, padding_size:padded_size-padding_size]
#     padded_input[padding_size:padded_size-padding_size, i] = padded_input[padding_size:padded_size-padding_size, padding_size]
#     padded_input[padding_size:padded_size-padding_size, padded_size-i-1] = padded_input[padding_size:padded_size-padding_size, padded_size-padding_size-1]
padded_input = np.zeros((padded_size, padded_size))
for i in range(padded_size):
    for j in range(padded_size):
        if i < padding_size and j < padding_size:  # 左上角
            padded_input[i, j] = input_image[0, 0]
        elif i < padding_size and j >= padding_size and j < input_size + padding_size:  # 上邊界
            padded_input[i, j] = input_image[0, j - padding_size]
        elif i < padding_size and j >= input_size + padding_size:  # 右上角
            padded_input[i, j] = input_image[0, -1]
        elif i >= padding_size and i < input_size + padding_size and j < padding_size:  # 左邊界
            padded_input[i, j] = input_image[i - padding_size, 0]
        elif i >= padding_size and i < input_size + padding_size and j >= padding_size and j < input_size + padding_size:  # 中間部分
            padded_input[i, j] = input_image[i -
                                             padding_size, j - padding_size]
        elif i >= padding_size and i < input_size + padding_size and j >= input_size + padding_size:  # 右邊界
            padded_input[i, j] = input_image[i - padding_size, -1]
        elif i >= input_size + padding_size and j < padding_size:  # 左下角
            padded_input[i, j] = input_image[-1, 0]
        elif i >= input_size + padding_size and j >= padding_size and j < input_size + padding_size:  # 下邊界
            padded_input[i, j] = input_image[-1, j - padding_size]
        elif i >= input_size + padding_size and j >= input_size + padding_size:  # 右下角
            padded_input[i, j] = input_image[-1, -1]

# 定義 Atrous Convolution 的輸出圖像
output_image = np.zeros((output_size, output_size))
for i in range(output_size):
    for j in range(output_size):
        # 計算 Atrous Convolution 的輸出值
        input_slice = padded_input[i*atrous_rate:i *
                                   atrous_rate+3, j*atrous_rate:j*atrous_rate+3]
        conv_value = 0.0
        for k in range(3):
            for l in range(3):
                conv_value += input_slice[k, l] * kernel[k, l]
        # 將輸出值存入輸出圖像中
        output_image[i, j] = conv_value

# 定義 ReLU Activation 的輸出圖像
relu_output = np.zeros((output_size, output_size))
for i in range(output_size):
    for j in range(output_size):
        # 計算 ReLU Activation 的輸出值
        relu_output[i, j] = max(output_image[i, j], 0)

# 輸出結果
print(relu_output.shape)  # (64, 64)
