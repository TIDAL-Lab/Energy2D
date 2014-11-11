/*
 *   Copyright (C) 2009  The Concord Consortium, Inc.,
 *   25 Love Lane, Concord, MA 01742
 */
part of Energy2D;

/**
 * @author Charles Xie
 *
 */
class HeatSolver2D {

  int nx, ny, nx1, ny1, nx2, ny2;

  ThermalBoundary boundary;

  Matrix<double> specificHeat;

  Matrix<double> conductivity, density, q, tb, t0;

  Matrix<double> u, v;

  Matrix<bool> fluidity;

  double deltaX, deltaY;
  double timeStep = 0.2;
  double backgroundTemperature = 0.0;
  double zHeatDiffusivity = 0.0;

  int relaxationSteps = 5; //5;


  HeatSolver2D(this.nx, this.ny) {
    nx1 = nx - 1;
    ny1 = ny - 1;
    nx2 = nx - 2;
    ny2 = ny - 2;

    t0 = new Matrix<double>(nx, ny, 0.0);

    boundary = new NeumannThermalBoundary();
  }


 void reset() {
    print('resetting');
    for (int i = 0; i < nx; i++) {
      for (int j=0; j<ny; j++) {
        t0[i][j] = 0.0;
      }
    }
  }

  void setTimeStep(double timeStep) {
    this.timeStep = timeStep;
  }

  double getTimeStep() {
    return timeStep;
  }


  void setFluidity(Matrix<bool> fluidity) {
    this.fluidity = fluidity;
  }

  void setGridCellSize(double deltaX, double deltaY) {
    this.deltaX = deltaX;
    this.deltaY = deltaY;
  }


  void setBoundary(ThermalBoundary boundary) {
    this.boundary = boundary;
  }

  ThermalBoundary getBoundary() {
    return boundary;
  }


  void setVelocity(Matrix<double> u, Matrix<double> v) {
    this.u = u;
    this.v = v;
  }


  void setConductivity(Matrix<double> conductivity) {
    this.conductivity = conductivity;
  }

  void setSpecificHeat(Matrix<double> specificHeat) {
    this.specificHeat = specificHeat;
  }

  void setDensity(Matrix<double> density) {
    this.density = density;
  }

  void setPower(Matrix<double> q) {
    this.q = q;
  }

  void setTemperatureBoundary(Matrix<double> tb) {
    this.tb = tb;
  }


  void solve(bool convective, Matrix<double> t) {

    // Copying a two-dimensional array is very fast: it takes less than 1% compared with the time for the relaxation solver below. Considering this, I chose clarity instead of swapping the arrays.
    t0.copyFrom(t);

    double hx = 0.5 / (deltaX * deltaX);
    double hy = 0.5 / (deltaY * deltaY);
    double rij, sij, axij, bxij, ayij, byij, cxij, cyij, dxij, dyij;
    double invTimeStep = 1.0 / timeStep;

    bool solveZ = zHeatDiffusivity != 0;

   for (int k = 0; k < relaxationSteps; k++) {
      for (int i = 1; i < nx1; i++) {
        for (int j = 1; j < ny1; j++) {

        if (tb[i][j] == null) {
            sij = specificHeat[i][j] * density[i][j] * invTimeStep;
            rij = conductivity[i][j];
            axij = hx * (rij + conductivity[i - 1][j]);
            bxij = hx * (rij + conductivity[i + 1][j]);
            ayij = hy * (rij + conductivity[i][j - 1]);
            byij = hy * (rij + conductivity[i][j + 1]);

            t[i][j] = (t0[i][j] * sij + q[i][j] + axij * t[i - 1][j] + bxij * t[i + 1][j] + ayij * t[i][j - 1] + byij * t[i][j + 1]) / (sij + axij + bxij + ayij + byij);

         if (solveZ && k == relaxationSteps - 1) {
              // use a simple proportional control only at the last step of relaxation
              t[i][j] -= zHeatDiffusivity * timeStep * (t0[i][j] - backgroundTemperature);
         }

        } else {
            t[i][j] = tb[i][j];
          }

        }
      }
      applyBoundary(t);
    }

   if (convective) {

      advect(t);
    }
  }


  void advect(Matrix<double> t) {
    macCormack(t);

  }


  // MacCormack
  void macCormack(Matrix<double> t) {

    double tx = 0.5 * timeStep / deltaX;
    double ty = 0.5 * timeStep / deltaY;
    for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (fluidity[i][j]) {
          t0[i][j] = t[i][j] - tx * (u[i + 1][j] * t[i + 1][j] - u[i - 1][j] * t[i - 1][j]) - ty * (v[i][j + 1] * t[i][j + 1] - v[i][j - 1] * t[i][j - 1]);
        }
      }
    }

    applyBoundary(t0);

    for (int i = 1; i < nx1; i++) {
      for (int j = 1; j < ny1; j++) {
        if (fluidity[i][j]) {
          t[i][j] = 0.5 * (t[i][j] + t0[i][j]) - 0.5 * tx * u[i][j] * (t0[i + 1][j] - t0[i - 1][j]) - 0.5 * ty * v[i][j] * (t0[i][j + 1] - t0[i][j - 1]);
        }
      }
    }

    applyBoundary(t);

  }


  void applyBoundary(Matrix<double> t) {

    if (boundary is DirichletThermalBoundary) {
      for (int i=0; i<nx; i++) {
        for (int j=0; j<ny; j++) {
          t[i][0] = boundary.upper;
          t[i][ny1] = boundary.lower;
          t[0][j] = boundary.left;
          t[nx1][j] = boundary.right;
        }
       }
     }

    else if (boundary is NeumannThermalBoundary) {

      // very small conductivity at the border could cause strange behaviors (e.g., huge number of isotherm lines), so impose a minimum
      double minConductivity = 0.001;
      for (int i = 0; i < nx; i++) {
        t[i][0] = t[i][1] + boundary.upper * deltaY / max(conductivity[i][0], minConductivity);
        t[i][ny1] = t[i][ny2] - boundary.lower * deltaY / max(conductivity[i][ny1], minConductivity);
      }
      for (int j = 0; j < ny; j++) {
        t[0][j] = t[1][j] - boundary.left * deltaX / max(conductivity[0][j], minConductivity);
        t[nx1][j] = t[nx2][j] + boundary.right * deltaX / max(conductivity[nx1][j], minConductivity);
      }
    }

  }


}
