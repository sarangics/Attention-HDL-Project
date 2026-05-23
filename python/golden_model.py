import numpy as np

# ==========================================================
# 256 = 1.0  (2^8 fractional bits)
# ==========================================================
SCALE = 256                         # 1.0 in Q8.8

def to_fixed(x):
    """Convert float to Q8.8 integer."""
    return int(x * SCALE)

def to_float(x):
    """Convert Q8.8 integer back to float."""
    return x / SCALE

# ==========================================================
# INPUT TOKENS  (plain integers — loaded as-is from hex file)
# ==========================================================
X = np.array([
    [1, 2, 3, 4],
    [5, 6, 7, 8]
], dtype=np.int32)

# ==========================================================
# WEIGHT MATRICES  (identity → Q = K = V = X)
# ==========================================================
WQ = np.eye(4, dtype=np.int32)
WK = np.eye(4, dtype=np.int32)
WV = np.eye(4, dtype=np.int32)

# ==========================================================
#  Q, K, V PROJECTIONS
# ==========================================================
Q = np.matmul(X, WQ)
K = np.matmul(X, WK)
V = np.matmul(X, WV)

print("\n========== Q MATRIX ==========")
print(Q)
print("\n========== K MATRIX ==========")
print(K)
print("\n========== V MATRIX ==========")
print(V)

# ==========================================================
# ATTENTION SCORES   (Q × Kᵀ)
# ==========================================================
scores = np.matmul(Q, K.T)

print("\n========== RAW SCORES ==========")
print(scores)

# ==========================================================
# SCALING   (÷ √dk, integer division)
# ==========================================================
dk       = 4
sqrt_dk  = int(np.sqrt(dk))         # = 2 for dk=4
scaled_scores = scores // sqrt_dk   # integer division, mirrors Verilog

print("\n========== SCALED SCORES ==========")
print(scaled_scores)



EXP_LUT = {0: 256, 1: 94, 2: 35, 3: 13, 4: 5, 5: 2, 6: 1}

def exp_lut(x):
    """
    Hardware-accurate exp approximation (mirrors Verilog exp_lut function).
    Input x must be ≤ 0 (guaranteed after max-subtraction).
    Returns exp(x) × 256 as integer (Q8.8, so 256 = 1.0).
    """
    if x >= 0:
        return 256                      # exp(0) = 1.0 = 256 in Q8.8
    return EXP_LUT.get(-x, 0)          # 0 for |x| ≥ 7

def softmax_hw(scaled_row):
    """
    Hardware softmax for one row.
    Returns list of integer weights in Q8.8 (sum ≈ 256 = 1.0).
    """
    # subtract row maximum (numerical stability + overflow prevention)
    max_val  = int(max(scaled_row))
    shifted  = [int(s) - max_val for s in scaled_row]

    # apply LUT exp to each shifted value
    exp_vals = [exp_lut(s) for s in shifted]
    sum_exp  = sum(exp_vals)

    # normalise  →  weight = (exp_val × 256) / sum_exp
    if sum_exp != 0:
        return [(e * SCALE) // sum_exp for e in exp_vals]
    return [0] * len(scaled_row)

N = X.shape[0]
weights_hw = np.array(
    [softmax_hw(scaled_scores[i]) for i in range(N)],
    dtype=np.int32
)

print("\n========== ATTENTION WEIGHTS (Q8.8 integers, 256 = 1.0) ==========")
print(weights_hw)
print("\n  As fractions:")
for i in range(N):
    row_pct = [f"{w/256*100:.1f}%" for w in weights_hw[i]]
    print(f"  Row {i}: {row_pct}  (sum = {sum(weights_hw[i])/256:.4f})")


# Integer matrix multiply then right-shift by 8 (= ÷ SCALE)
raw_output = np.matmul(weights_hw, V)   # still Q8.8 scaled
output     = raw_output >> 8            # rescale back to integer  (÷ 256)

print("\n========== FINAL OUTPUT ==========")
print(output)

# # ==========================================================
# # VERIFICATION — compare hardware output against float reference
# # ==========================================================
# print("\n========== VERIFICATION ==========")

# # True floating-point reference
# Q_f  = X.astype(float) @ WQ.astype(float)
# K_f  = X.astype(float) @ WK.astype(float)
# V_f  = X.astype(float) @ WV.astype(float)
# S_f  = Q_f @ K_f.T
# Sc_f = S_f / np.sqrt(dk)

# def true_softmax(row):
#     row = row - np.max(row)
#     e   = np.exp(row)
#     return e / e.sum()

# W_f     = np.array([true_softmax(Sc_f[i]) for i in range(N)])
# out_f   = W_f @ V_f

# print(f"\n  True softmax weights (float):")
# print(W_f)
# print(f"\n  True float output:")
# print(out_f)

# print(f"\n  Hardware output (integer):")
# print(output)

# print(f"\n  Difference (hardware − float reference):")
# diff = np.abs(output.astype(float) - out_f)
# print(diff)

# tolerance = 1.0
# if np.all(diff <= tolerance):
#     print(f"\n  PASS — all values within ±{tolerance} of float reference")
# else:
#     print(f"\n  FAIL — some values exceed ±{tolerance} tolerance")

# # ==========================================================
# # COMPARE AGAINST HARDWARE SIMULATION OUTPUT  (output.txt)
# # ==========================================================
# import os

# hw_output_file = "output/output.txt"
# if os.path.exists(hw_output_file):
#     print(f"\n========== HARDWARE FILE COMPARISON ({hw_output_file}) ==========")
#     hw_out = []
#     with open(hw_output_file) as f:
#         for line in f:
#             line = line.strip()
#             if line:
#                 hw_out.append([int(v) for v in line.split()])
#     hw_out = np.array(hw_out, dtype=np.int32)

#     print(f"\n  Golden  output:\n{output}")
#     print(f"\n  Hardware output:\n{hw_out}")

#     hw_diff = np.abs(output - hw_out)
#     print(f"\n  Difference:\n{hw_diff}")

#     if np.all(hw_diff <= 2):
#         print("\n  RESULT: PASS — hardware matches golden model within ±2 LSB")
#     else:
#         print("\n  RESULT: FAIL — mismatch detected")
#         for i in range(N):
#             for j in range(dk):
#                 if hw_diff[i][j] > 2:
#                     print(f"    OUT[{i}][{j}]  golden={output[i][j]}"
#                           f"  hw={hw_out[i][j]}  diff={hw_diff[i][j]}")
# else:
#     print(f"\n  NOTE: {hw_output_file} not found.")
#     print("  Run Verilog simulation first, then re-run this script.")