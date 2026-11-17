# Mathematical Formulation and Algorithmic Derivations

This document provides the full mathematical proofs and derivations for the **Weighted Guided Image Filter (WGIF)** and its application in **Retinex Illumination-Reflectance Decomposition**.

---

## 1. Guided Filter Core Derivation

### 1.1 Local Linear Model Assumption
In any local window $\omega_k$ of radius $r$ centered at pixel $k$, the output filtered image $q$ is assumed to be an affine linear transformation of the guidance image $I$:

$$q_i = a_k I_i + b_k, \quad \forall i \in \omega_k$$

where:
- $I_i$: Guidance image intensity at pixel $i$.
- $q_i$: Output image intensity at pixel $i$.
- $(a_k, b_k)$: Linear coefficients assumed constant inside window $\omega_k$.

Taking the gradient of both sides:
$$\nabla q = a_k \nabla I$$

This relationship ensures that the output image $q$ has an edge if and only if the guidance image $I$ has an edge, preserving essential structural boundaries.

---

### 1.2 Objective Cost Function Minimization
To ensure $q$ remains faithful to the input target image $p$, we define the penalized least-squares cost function:

$$E(a_k, b_k) = \sum_{i \in \omega_k} \left( (a_k I_i + b_k - p_i)^2 + \lambda a_k^2 \right)$$

where $\lambda$ (or $\epsilon$) is the Tikhonov regularization parameter preventing $a_k$ from growing unboundedly large.

#### Partial Derivative with respect to $b_k$:
$$\frac{\partial E}{\partial b_k} = \sum_{i \in \omega_k} 2(a_k I_i + b_k - p_i) = 0$$

Dividing by $2 |\omega|$ (where $|\omega|$ is the number of pixels in window $\omega_k$):
$$a_k \left( \frac{1}{|\omega|} \sum_{i \in \omega_k} I_i \right) + b_k - \left( \frac{1}{|\omega|} \sum_{i \in \omega_k} p_i \right) = 0$$

Let $\mu_k = \frac{1}{|\omega|} \sum_{i \in \omega_k} I_i$ and $\bar{p}_k = \frac{1}{|\omega|} \sum_{i \in \omega_k} p_i$:
$$a_k \mu_k + b_k - \bar{p}_k = 0 \implies b_k = \bar{p}_k - a_k \mu_k \quad \text{--- (Eq. 1)}$$

#### Partial Derivative with respect to $a_k$:
$$\frac{\partial E}{\partial a_k} = \sum_{i \in \omega_k} 2(a_k I_i + b_k - p_i) I_i + 2 \lambda a_k = 0$$

Substitute $b_k = \bar{p}_k - a_k \mu_k$:
$$\sum_{i \in \omega_k} \left( a_k I_i + \bar{p}_k - a_k \mu_k - p_i \right) I_i + \lambda a_k = 0$$
$$\sum_{i \in \omega_k} \left[ a_k (I_i - \mu_k) I_i - (p_i - \bar{p}_k) I_i \right] + \lambda a_k = 0$$

Since $\sum_{i \in \omega_k} (I_i - \mu_k) \mu_k = 0$ and $\sum_{i \in \omega_k} (p_i - \bar{p}_k) \mu_k = 0$:
$$a_k \sum_{i \in \omega_k} (I_i - \mu_k)^2 - \sum_{i \in \omega_k} (p_i - \bar{p}_k)(I_i - \mu_k) + \lambda a_k = 0$$

Dividing by $|\omega|$:
$$a_k \sigma_k^2 - \sigma_{Ip, k} + \frac{\lambda}{|\omega|} a_k = 0$$
where $\sigma_k^2$ is the variance of $I$ in $\omega_k$, and $\sigma_{Ip, k}$ is the covariance of $I$ and $p$.
Absorbing the scale into $\lambda$:
$$a_k = \frac{\sigma_{Ip, k}}{\sigma_k^2 + \lambda} \quad \text{--- (Eq. 2)}$$

---

## 2. The Root Cause of Halo Artifacts in GIF
Analyze $a_k$ in Eq. 2 when guidance image $I = p$:
$$a_k = \frac{\sigma_k^2}{\sigma_k^2 + \lambda}$$

1. In a flat region ($\sigma_k^2 \ll \lambda$): $a_k \approx 0 \implies q_i \approx \bar{p}_k$ (average blur).
2. Near a sharp edge ($\sigma_k^2 \gg \lambda$): $a_k \to 1 \implies q_i \approx I_i$ (edge preserved).

**The Dilemma:**
A fixed scalar $\lambda$ cannot satisfy both criteria simultaneously across an image:
- If $\lambda$ is set large enough to smooth out shadows and camera noise in flat regions, $\lambda$ is no longer negligible compared to $\sigma_k^2$ near edges.
- As a result, $a_k$ drops significantly below 1 (e.g., $a_k \approx 0.7$), smoothing across edge boundaries and generating visible **halo fringes**.

---

## 3. Weighted Guided Image Filter (WGIF) Derivation

### 3.1 Adaptive Cost Function
To eliminate halos, WGIF replaces the static penalty $\lambda$ with an edge-weighted penalty $\frac{\lambda}{\Gamma_G(k)}$:

$$E(a_k, b_k) = \sum_{i \in \omega_k} \left( (a_k I_i + b_k - p_i)^2 + \frac{\lambda}{\Gamma_G(k)} a_k^2 \right)$$

Solving the minimization gives:
$$a_k = \frac{\sigma_{Ip, k}}{\sigma_k^2 + \frac{\lambda}{\Gamma_G(k)}} \quad \text{--- (Eq. 3)}$$
$$b_k = \bar{p}_k - a_k \mu_k$$

### 3.2 Formulation of Edge Weighting $\Gamma_G(k)$
Let $\sigma_{G, 1}^2(k)$ be the variance in a $3 \times 3$ window ($r_1 = 1$). To make $\Gamma_G(k)$ scale-invariant across the image:

$$\Gamma_G(k) = \frac{\sigma_{G, 1}^2(k) + \varepsilon}{\left( \frac{1}{N} \sum_{i=1}^N \frac{1}{\sigma_{G, 1}^2(i) + \varepsilon} \right)^{-1}} = (\sigma_{G, 1}^2(k) + \varepsilon) \cdot \left[ \frac{1}{N} \sum_{i=1}^N \frac{1}{\sigma_{G, 1}^2(i) + \varepsilon} \right]$$

where $\varepsilon = (0.001 \times L)^2$ is a small bias constant.

### 3.3 Dynamic Regularization Behavior
- **Edge Pixels:**
  $\sigma_{G, 1}^2(k) \gg \text{mean variance} \implies \Gamma_G(k) \gg 1$.
  The effective regularization $\frac{\lambda}{\Gamma_G(k)} \to 0$.
  Hence $a_k \to 1$, completely preserving the sharp gradient and eliminating edge halos.
- **Flat Pixels:**
  $\sigma_{G, 1}^2(k) \ll \text{mean variance} \implies \Gamma_G(k) < 1$.
  The effective regularization $\frac{\lambda}{\Gamma_G(k)}$ increases by an order of magnitude.
  Hence $a_k \to 0$, producing strong, uniform smoothing across shadowed zones.

---

## 4. $O(N)$ Computational Complexity via 2D Integral Images
Both Guided Filter and WGIF require calculating local box averages over window radius $r$.
Using 2D Integral Images (Summed-Area Tables):
$$II(x, y) = \sum_{x' \le x, y' \le y} f(x', y')$$

The local sum over window $[x_0, x_1] \times [y_0, y_1]$ is calculated in **$O(1)$ operations**:
$$\text{Sum} = II(x_1, y_1) - II(x_0 - 1, y_1) - II(x_1, y_0 - 1) + II(x_0 - 1, y_0 - 1)$$

Thus, the overall algorithmic time complexity for an image with $N$ pixels is:
$$\mathcal{O}(N)$$
**strictly independent** of the window radius $r$.
