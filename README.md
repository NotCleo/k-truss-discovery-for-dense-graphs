# k-Truss Discovery in Graphs

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/NotCleo/k-truss-discovery-in-graphs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This project implements a **CUDA-based k-truss discovery algorithm** for dense graphs. A **k-truss** is a subgraph where each edge is part of at least `k-2` triangles, making it a powerful tool for identifying dense and cohesive structures in networks, such as communities in social networks or dense subgraphs in biological networks.

---

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

---

## Installation

To build and run this project, you will need:

- **CUDA 12.x or higher** (compatible with your GPU, e.g., NVIDIA H100)
- **CMake 3.10 or higher**
- A C++ compiler (e.g., `g++`)

### Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/NotCleo/k-truss-discovery-in-graphs.git
   cd k-truss-discovery-in-graphs
