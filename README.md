# Replication: Sign Restrictions in SVAR (Fry and Pagan, 2011)

[Language: [Japanese](#japanese) / [English](#english)]

---

<a name="japanese"></a>
## 🇯🇵日本語での説明

### 1. 概要
本プロジェクトでは、Fry and Pagan (2011) の手法を用い、符号制限（Sign Restrictions）を用いた構造ベクトル自己回帰（SVAR）モデルの特定と、その課題を解決する **Median Target (MT) method** をRで実装しました。

### 2. 背景と目的
SVARモデルにおいて、誘導型（Reduced-form）から構造ショックを一意に特定（Identification）することは困難です。
従来の符号制約では、合格した全モデルのインパルス応答から、各時点ごとに中央値を抽出した「点別中央値」が使われてきましたが、Fry and Pagan (2011) はこれに対し、「合成されたIRFは単一の構造モデルを反映しておらず、ショックの直交性も保たれない」という論理的整合性の欠如を指摘しました。
本リポジトリでは、実在する単一のモデルから中央値に最も近いものを選択するMT法を適用し、論理的一貫性のある分析を行っています。

### 3. モデルとデータ
#### 3.1 モデル定式化
$$z_t = A_1 z_{t-1} + \dots + A_6 z_{t-6} + e_t$$
$$e_t = B \epsilon_t, \quad E[\epsilon_t \epsilon_t'] = I$$

**記号の説明**
* $z_t$: 内生変数のベクトル ($y_{gap}, CPI_{infl}, FEDFUNDS$)
* $A_p$: 誘導型モデルの係数行列 ($p=1, \dots, 6$)
* $e_t$: 誘導型残差のベクトル ($e_t \sim N(0, \Omega)$)
* $B$: 構造ショックが変数に与える同時点の影響を規定する識別行列
* $\epsilon_t$: 構造ショックのベクトル（各ショックは互いに無相関と仮定）
* $I$: 単位行列（構造ショックの分散が1で直交していることを示す）

#### 3.2 データソース (FRED)
* **Real GDP (GDPC1)**: [FRED Link](https://fred.stlouisfed.org/series/GDPC1) (産出量ギャップ算出に使用)
* **CPI (CPIAUCSL)**: [FRED Link](https://fred.stlouisfed.org/series/CPIAUCSL) (インフレ率算出に使用)
* **Federal Funds Rate (FEDFUNDS)**: [FRED Link](https://fred.stlouisfed.org/series/FEDFUNDS)

### 4. 分析結果
推定された特性根（Roots）はすべて1未満であり、系は安定しています。インパルス応答関数（IRF）は、金融引き締めショックが景気と物価を抑制するという理論通りの結果を示しました。

![Impulse Response Function](output/irf_mp_shock_mt.png)

### 5. 拡張性と展望
* **多変数化**: 為替レートや原油価格を追加したモデルへの拡張。
* **複数ショックの識別**: 供給ショック（AS）と需要ショック（AD）の同時特定。

---

<a name="english"></a>
## 🇺🇸 English Description

### 1. Overview
This project implements the **Median Target (MT) method** in R to address identification issues in Structural VAR (SVAR) models using sign restrictions, following the methodology of Fry and Pagan (2011).

### 2. Objectives
Fry and Pagan (2011) criticized the traditional "the median of the impulse responses" IRF because it does not correspond to any single structural model and fails to ensure the orthogonality of shocks. This implementation uses the MT method to select the single best-fitting model from the set of accepted candidates, ensuring logical and statistical consistency.

### 3. Specification & Data
#### 3.1 Model Specification
$$z_t = A_1 z_{t-1} + \dots + A_6 z_{t-6} + e_t$$
$$e_t = B \epsilon_t, \quad E[\epsilon_t \epsilon_t'] = I$$

**List of Symbols**
* $z_t$: Vector of endogenous variables ($y_{gap}, CPI_{infl}, FEDFUNDS$).
* $A_p$: Coefficient matrices of the reduced-form model ($p=1, \dots, 6$).
* $e_t$: Vector of reduced-form residuals ($e_t \sim N(0, \Omega)$).
* $B$: Identification matrix representing the contemporaneous impact of structural shocks.
* $\epsilon_t$: Vector of structural shocks (assumed to be mutually uncorrelated).
* $I$: Identity matrix (implying structural shocks are orthogonal with unit variance).

#### 3.2 Data Sources (FRED)
* **Real GDP**: Output gap derived from [GDPC1](https://fred.stlouisfed.org/series/GDPC1).
* **CPI**: Inflation rate derived from [CPIAUCSL](https://fred.stlouisfed.org/series/CPIAUCSL).
* **Federal Funds Rate**: Monetary policy instrument ([FEDFUNDS](https://fred.stlouisfed.org/series/FEDFUNDS)).

### 4. Key Findings
The characteristic roots (Max: 0.918) indicate that the VAR system is stable. The IRFs demonstrate that a contractionary monetary policy shock leads to a temporary decline in both output and inflation.

### 5. Future Extensions
* **Larger Systems**: Incorporating exchange rates or commodity prices.
* **Multiple Shocks**: Simultaneous identification of Aggregate Supply and Demand shocks.