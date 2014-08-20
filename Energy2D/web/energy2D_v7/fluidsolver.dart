part of Energy2D;
/*
 *   Copyright (C) 2009  The Concord Consortium, Inc.,
 *   25 Love Lane, Concord, MA 01742
 *
 */

/**
 * @author Charles Xie
 *
 */
 class FluidSolver2D {

  // five relaxation steps are probably enough for most transient problems because there are numerous previous steps that can be considered as pre-relaxation steps, especially when changes are slow or small.
  int relaxationSteps = 2; //5

  // 10 * Constants.AIR_VISCOSITY;
  double viscosity = 10 * 0.00001568;
  double thermalBuoyancy = 0.00025;
  double gravity = 0.0;
  int buoyancyApproximation = Model2D.BUOYANCY_AVERAGE_ALL;
  int gravityType = Model2D.GRAVITY_UNIFORM;
  double timeStep =  0.2; //0.1;

  int nx, ny, nx1, ny1, nx2, ny2;
  double deltaX, deltaY;
  double i2dx, i2dy;
  double idxsq, idysq;

  Matrix<double> u0, v0, t, vorticity, stream;
  Matrix<bool> fluidity;


  MassBoundary boundary;

  FluidSolver2D(this.nx, this.ny) {
    nx1 = nx - 1;
    ny1 = ny - 1;
    nx2 = nx - 2;
    ny2 = ny - 2;
    u0 = new   Matrix<double> (nx, ny, 0.0);
    v0 = new Matrix<double> (nx, ny, 0.0);

    boundary = new SimpleMassBoundary();
  }

  void reset() {
    for (int i = 0; i < nx; i++) {
      for (int j=0; j<ny; j++)  {
        u0[i][j]=0.0;
        v0[i][j]=0.0;
      }
    }
    if (vorticity != null) {
      for (int i = 0; i < nx; i++) {
        for (int j=0; j<ny; j++){
          u0[i][j]=0.0;
        }
      }
    }
    if (stream != null) {
      for (int i = 0; i < nx; i++) {
        for (int j=0; j<ny; j++) {
          stream[i][j]=0.0;
        }
      }
    }
  }


  void setBoundary(MassBoundary boundary) {
    this.boundary = boundary;
  }


  MassBoundary getBoundary() {
    return boundary;
  }


  void setGravityType(int gravityType) {
    this.gravityType = gravityType;
  }


  int getGravityType() {
    return gravityType;
  }


  void setBuoyancyApproximation(int buoyancyApproximation) {
    this.buoyancyApproximation = buoyancyApproximation;
  }


  int getBuoyancyApproximation() {
    return buoyancyApproximation;
  }


  void setThermalBuoyancy(double thermalBuoyancy) {
    this.thermalBuoyancy = thermalBuoyancy;
  }


  double getThermalBuoyancy() {
    return thermalBuoyancy;
  }


  void setBackgroundViscosity(double viscosity) {
    this.viscosity = viscosity;
  }


  double getViscosity() {
    return viscosity;
  }


  void setTemperature(Matrix<double> t) {
    this.t = t;
  }


  void setFluidity(Matrix<bool> fluidity) {
    this.fluidity = fluidity;
  }

  void setGridCellSize(double deltaX, double deltaY) {
    this.deltaX = deltaX;
    this.deltaY = deltaY;
    i2dx = 0.5 / deltaX;
    i2dy = 0.5 / deltaY;
    idxsq = 1 / (deltaX * deltaX);
    idysq = 1 / (deltaY * deltaY);
  }


  void setTimeStep(double timeStep) {
    this.timeStep = timeStep;
  }


  double getTimeStep() {
    return timeStep;
  }


  void setObstacleVelocity(Matrix<double> u, Matrix<double> v) {
    int count = 0;
    double uw, vw;

   /* for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (!fluidity[i][j]) {
          uw = 0.0; //uWind[i][j];
          vw = 0.0; //vWind[i][j];
          count = 0;
          if (fluidity[i - 1][j]) {
            count++;
            u[i][j] = uw - u[i - 1][j];
            v[i][j] = vw + v[i - 1][j];
          } else if (fluidity[i + 1][j]) {
            count++;
            u[i][j] = uw - u[i + 1][j];
            v[i][j] = vw + v[i + 1][j];
          }
          if (fluidity[i][j - 1]) {
            count++;
            u[i][j] = uw + u[i][j - 1];
            v[i][j] = vw - v[i][j - 1];
          } else if (fluidity[i][j + 1]) {
            count++;
            u[i][j] = uw + u[i][j + 1];
            v[i][j] = vw - v[i][j + 1];
          }
          if (count == 0) {
            u[i][j] = uw;
            v[i][j] = vw;
          }
        }
      }
    } */

  }


  // ensure dx/dn = 0 at the boundary (the Neumann boundary condition)
  void setObstacleBoundary(Matrix<double> x) {
    for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (!fluidity[i][j]) {
          if (fluidity[i - 1][j]) {
            x[i][j] = x[i - 1][j];
          } else if (fluidity[i + 1][j]) {
            x[i][j] = x[i + 1][j];
          }
          if (fluidity[i][j - 1]) {
            x[i][j] = x[i][j - 1];
          } else if (fluidity[i][j + 1]) {
            x[i][j] = x[i][j + 1];
           }
         }
       }
     }
   }

  double getMeanTemperature(int i, int j) {
    int lowerBound = 0;
    // search for the upper bound
    for (int k = j - 1; k > 0; k--) {
      if (!fluidity[i][k]) {
        lowerBound = k;
        break;
      }
    }

    int upperBound = ny;
    for (int k = j + 1; k < ny; k++) {
      if (!fluidity[i][k]) {
        upperBound = k;
        break;
      }
    }

    double t0 = 0.0;
    for (int k = lowerBound; k < upperBound; k++) {
      t0 += t[i][k];
    }
    return t0 / (upperBound - lowerBound);
  }


  // Boussinesq approximation: density differences are sufficiently small to be neglected, except where they appear in terms multiplied by g, the acceleration due to gravity.
  void applyBuoyancy(Matrix<double> f) {

    double g = gravity * timeStep;
    double b = thermalBuoyancy * timeStep;
    double t0;


    switch (buoyancyApproximation) {

    case Model2D.BUOYANCY_AVERAGE_ALL:
      t0 = MathUtil.getAverage(t);
      for (int i = 1; i < nx1; i++) {
        for (int j = 1; j < ny1; j++) {
          if (fluidity[i][j]) {
            f[i][j] += (g - b) * t[i][j]  + b * t0;
          }
        }
      }
      break;

    case Model2D.BUOYANCY_AVERAGE_COLUMN:

      for (int i = 1; i < nx1; i++) {
        for (int j = 1; j < ny1; j++) {
          if (fluidity[i][j]) {
            t0 = getMeanTemperature(i, j);
            f[i][j] += (g - b) * t[i][j] + b * t0;
          }
        }
      }
      break;
    }
  }


  void diffuse(int b, Matrix<double> f0, Matrix<double> f) {

      // Copying a two-dimensional array is very fast: it takes less than 1% compared with the time for the relaxation solver below. Considering this, I chose clarity instead of swapping the arrays.
    f0.copyFrom(f);

    double hx = timeStep * viscosity * nx1 * ny1;
  //  double hy = timeStep * viscosity * ny1 * ny1;
  //  double dn = 1.0 / (1 + 2 * (hx + hy));

    for (int k = 0; k < relaxationSteps; k++) {
      for (int i = 1; i < nx1; i++) {
        for (int j = 1; j < ny1; j++) {
          if (fluidity[i][j]) {
            f[i][j] = (f0[i][j] + hx * (f[i - 1][j] + f[i + 1][j] + f[i][j - 1] + f[i][j + 1])) / (1 + 4 * hx);
          }
        }
      }
      applyBoundary(b, f);
    }
  }


  void advect(int b, Matrix<double> f0, Matrix<double> f) {
    macCormack(b, f0, f);
  }

  // MacCormack
  void macCormack(int b, Matrix<double> f0, Matrix<double> f) {
    double tx = 0.5 * timeStep / deltaX;
    double ty = 0.5 * timeStep / deltaY;

    for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (fluidity[i][j]) {
          f[i][j] = f0[i][j] - tx * (u0[i + 1][j] * f0[i + 1][j] - u0[i - 1][j] * f0[i - 1][j]) - ty * (v0[i][j + 1] * f0[i][j + 1] - v0[i][j - 1] * f0[i][j - 1]);
        }
      }
    }
    applyBoundary(b, f);

    for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (fluidity[i][j]) {
          f0[i][j] = 0.5 * (f0[i][j] + f[i][j]) - 0.5 * tx * u0[i][j] * (f[i + 1][j] - f[i - 1][j]) - 0.5 * ty * v0[i][j] * (f[i][j + 1] - f[i][j - 1]);
        }
      }
    }

    f.copyFrom(f0);
    applyBoundary(b, f);
  }


	void solve(Matrix<double> u, Matrix<double> v) {
    if (thermalBuoyancy != 0) {
      switch (gravityType) {
        case Model2D.GRAVITY_UNIFORM:
          applyBuoyancy(v);
          break;
      //  case Model2D.GRAVITY_CENTRIC:
      //    applySphericalBuoyancy(u, v);
      //    break;
      }
    }
    setObstacleVelocity(u, v);
    if (viscosity > 0) { // viscid
      diffuse(1, u0, u);
      diffuse(2, v0, v);
      conserve(u, v, u0, v0);
      setObstacleVelocity(u, v);
    }

    u0.copyFrom(u);
    v0.copyFrom(v);

    advect(1, u0, u);
    advect(2, v0, v);
    conserve(u, v, u0, v0);
    setObstacleVelocity(u, v);
  }


  /*
   * enforce the continuity condition div(V)=0 (velocity field must be divergence-free to conserve mass) using the relaxation method: http://en.wikipedia.org/wiki/Relaxation_method. This procedure solves the Poisson equation.
   */
  void conserve(Matrix<double> u, Matrix<double> v, Matrix<double> phi, Matrix<double> div) {

    for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (fluidity[i][j]) {
          div[i][j] = (u[i + 1][j] - u[i - 1][j]) * i2dx + (v[i][j + 1] - v[i][j - 1]) * i2dy;
          phi[i][j] = 0.0;
        }
      }
    }
    applyBoundary(0, div);
    applyBoundary(0, phi);
    setObstacleBoundary(div);
    setObstacleBoundary(phi);

    double s = 0.5 / (idxsq + idysq);

    for (int k = 0; k < relaxationSteps; k++) {
      for (int i = 1; i < nx1; i++) {
        for (int j = 1; j < ny1; j++) {
          if (fluidity[i][j]) {
            phi[i][j] = s * ((phi[i - 1][j] + phi[i + 1][j]) * idxsq + (phi[i][j - 1] + phi[i][j + 1]) * idysq - div[i][j]);
          }
        }
      }
    }

    for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (fluidity[i][j]) {
          u[i][j] -= (phi[i + 1][j] - phi[i - 1][j]) * i2dx;
          v[i][j] -= (phi[i][j + 1] - phi[i][j - 1]) * i2dy;
        }
      }
    }
    applyBoundary(1, u);
    applyBoundary(2, v);
  }


  Matrix<double> getStreamFunction(Matrix<double> u, Matrix<double> v) {
    if (vorticity == null)
      vorticity = new Matrix<double> (nx, ny, 0.0);
    if (stream == null)
      stream = new Matrix<double> (nx, ny, 0.0);
    calculateVorticity(u, v);
    calculateStreamFunction();
    return stream;
  }


  void calculateStreamFunction() {
   double s = 0.5 / (idxsq + idysq);
    for (int i = 0; i < nx; i++) {
      for (int j=0; j<ny; j++) {
        stream[i][j]=0.0;
      }
    }


    for (int k = 0; k < relaxationSteps; k++) {
      for (int i = 1; i < nx1; i++) {
        for (int j = 1; j < ny1; j++) {
          if (fluidity[i][j]) {
            stream[i][j] = s * ((stream[i - 1][j] + stream[i + 1][j]) * idxsq + (stream[i][j - 1] + stream[i][j + 1]) * idysq + vorticity[i][j]);
          }
        }
      }
      applyBoundary(0, stream);
      setObstacleBoundary(stream);
    }
  }

  void calculateVorticity(Matrix<double> u, Matrix<double> v) {
    double du_dy, dv_dx;
    for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (fluidity[i][j]) {
          du_dy = (u[i][j + 1] - u[i][j - 1]) / (2 * deltaY);
          dv_dx = (v[i + 1][j] - v[i - 1][j]) / (2 * deltaX);
          vorticity[i][j] = du_dy - dv_dx;
        }
      }
    }
    applyBoundary(0, vorticity);
    setObstacleBoundary(vorticity);
  }

  // b=1 horizontal; b=2 vertical
  void applyBoundary(int direction, Matrix<double> f) {

    bool horizontal = direction == 1;
    bool vertical = direction == 2;
    for (int i = 1; i < nx1; i++) {
      // upper side; value of 0 denotes refelective surface
      if (vertical && boundary.upper == MassBoundary.REFLECTIVE) {
        f[i][0] = -f[i][1];
      } else {
        f[i][0] = f[i][1];
      }
      // lower side; value of 0 denotes refelective surface
      if (vertical && boundary.lower == MassBoundary.REFLECTIVE) {
        f[i][ny1] = -f[i][ny2];
      } else {
        f[i][ny1] = f[i][ny2];
      }
    }
    for (int j = 1; j < ny1; j++) {
      // left side; value of 0 denotes refelective surface
      if (horizontal && boundary.left == MassBoundary.REFLECTIVE) {
        f[0][j] = -f[1][j];
      } else {
        f[0][j] = f[1][j];
      }
      // right side; value of 0 denotes refelective surface
      if (horizontal && boundary.right == MassBoundary.REFLECTIVE) {
        f[nx1][j] = -f[nx2][j];
      } else {
        f[nx1][j] = f[nx2][j];
      }
    }
    // upper-left corner
    f[0][0] = 0.5 * (f[1][0] + f[0][1]);
    // upper-right corner
    f[nx1][0] = 0.5 * (f[nx2][0] + f[nx1][1]);
    // lower-left corner
    f[0][ny1] = 0.5 * (f[1][ny1] + f[0][ny2]);
    // lower-right corner
    f[nx1][ny1] = 0.5 * (f[nx2][ny1] + f[nx1][ny2]);
  }
}