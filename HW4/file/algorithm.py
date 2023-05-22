import numpy as np
import cv2
import sys
import struct


def input_image():
    image = cv2.imread("C:\\Graduate School\\IC_DESIGN\\HW4\\file\\bleach.png")
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    gray = cv2.resize(gray, (64, 64))
    print(gray)
    return gray


def padding(image):
    padded_image = np.zeros((68, 68))
    padded_image[2:66, 2:66] = image
    # use double for loop intentionally
    for i in range(68):
        for j in range(68):
            if i < 2 and j < 2:  # left-top corner
                padded_image[i, j] = padded_image[2, 2]
            elif i >= 66 and j < 2:  # left-buttom corner
                padded_image[i, j] = padded_image[65, 2]
            elif i < 2 and j >= 66:  # right-top corner
                padded_image[i, j] = padded_image[2, 65]
            elif i >= 66 and j >= 66:  # right-buttom corner
                padded_image[i, j] = padded_image[65, 65]
            elif i < 2 and j >= 2 and j < 66:  # top side
                padded_image[i, j] = padded_image[2, j]
            elif i >= 66 and j >= 2 and j < 66:  # buttom side
                padded_image[i, j] = padded_image[65, j]
            elif i >= 2 and i < 66 and j < 2:  # left side
                padded_image[i, j] = padded_image[i, 2]
            elif i >= 2 and i < 66 and j >= 66:  # right side
                padded_image[i, j] = padded_image[i, 65]
    return padded_image


def Atrous_Convolution(padded_image):
    # use for loop purposely
    padded_image = np.array(padded_image, np.float32)
    kernel = np.array([[-0.0625, -0.125, -0.0625],
                       [-0.25, 1, -0.25],
                       [-0.0625, -0.125, -0.0625]])
    bias = -0.75
    output_image = np.zeros((64, 64), np.float32)
    for i in range(2, 66):
        for j in range(2, 66):
            output_image[i-2, j-2] = (padded_image[i-2, j-2]*kernel[0, 0] +
                                      padded_image[i-2, j]*kernel[0, 1] +
                                      padded_image[i-2, j+2]*kernel[0, 2] +
                                      padded_image[i, j-2]*kernel[1, 0] +
                                      padded_image[i, j]*kernel[1, 1] +
                                      padded_image[i, j+2]*kernel[1, 2] +
                                      padded_image[i+2, j-2]*kernel[2, 0] +
                                      padded_image[i+2, j]*kernel[2, 1] +
                                      padded_image[i+2, j+2]*kernel[2, 2] +
                                      bias)

    return output_image


def RELU(image):
    for i in range(64):
        for j in range(64):
            if (image[i, j] <= 0):
                image[i, j] = 0
            else:
                image[i, j] = image[i, j]
    # image = np.array(image, np.uint8)
    # print(image)
    return image


def Max_pooling(image):
    output_image = np.zeros((32, 32))
    stride = 2
    for i in range(32):
        for j in range(32):
            max = -float("inf")
            for m in range(2):
                for n in range(2):
                    row = i * stride + m
                    col = j * stride + n
                    if image[row, col] > max:
                        max = image[row, col]
            output_image[i, j] = max
    # seems to be requested by TA
    output_image = np.array(output_image, np.uint8)
    # print(output_image)
    return output_image


def convert(arr):
    scale_factor = 2**4
    arr *= scale_factor
    arr = np.round(arr)
    arr = np.clip(arr, -2**12, 2**12-1)
    arr = arr.astype(np.int16)
    return arr


def write_file(image, path2):
    height, width = image.shape[:2]
    fo = open(path2, "w")
    for i in range(width):
        for j in range(height):
            format(image[i, j], '013b')+"\n"
            str = format(image[i, j], '013b')+"\n"
            fo.write(str)
    fo.close()


if __name__ == '__main__':
    image = input_image()
    write_file(image, "./img.dat")
    padded_image = padding(image)
    image_conv = Atrous_Convolution(padded_image)
    image_relu = RELU(image_conv)
    arr1 = convert(image_relu)
    # print(arr1)
    write_file(arr1, "./layer0_golden.dat")

    result = Max_pooling(image_relu)
    arr2 = convert(result)
    write_file(arr2, "./layer1_golden.dat")
    cv2.imshow('Image', image_relu)
    cv2.waitKey(0)
