part of Energy2D;



/**
 * Units:
 *
 * Temperature: centigrade; Length: meter; Time: second; Thermal diffusivity: m^2/s; Power: centigrade/second.
 *
 * Using a 1D array and then a convenience function I(i, j) =i + j x ny to find t(i, j) is about 12% faster than using a 2D array directly (Java 6).
 * Hence, using 1D array for 2D functions doesn't result in significant performance improvements.
 *
 * @author Charles Xie
 *
 */
class Model2D {

  static const int BUOYANCY_AVERAGE_ALL = 1;
  static const int BUOYANCY_AVERAGE_COLUMN = 0;
  static const int GRAVITY_UNIFORM = 0;
  static const int GRAVITY_CENTRIC = 1;

  int indexOfStep = 0;

  //10 * Constants.AIR_THERMAL_CONDUCTIVITY
  double backgroundConductivity = 10 * 0.025;

  //Constants.AIR_SPECIFIC_HEAT
  double backgroundSpecificHeat = 1012.0;

  // Constants.AIR_DENSITY
  double backgroundDensity = 1.204;

  double backgroundTemperature = 0.0;

  double maximumHeatCapacity = -1.00;

  // temperature array
  Matrix<double> t;

  // velocity x-component array (m/s)
  Matrix<double> u;

  // velocity y-component array (m/s)
  Matrix<double> v;

  // internal temperature boundary array
  Matrix<double> tb;

  // internal heat generation array
  Matrix<double> q;

  // conductivity array
  Matrix<double> conductivity;

  // specific heat array
  Matrix<double> specificHeat;

  // density array
  Matrix<double> density;

  // fluid cell array
  Matrix<bool> fluidity;

  List<Part> parts;

  FluidSolver2D fluidSolver;
  HeatSolver2D heatSolver;

  // number of grid cells
  int nx = 50;
  int ny = 50;

  // grid length in x direction (unit: meter)
  double lx = 10.0;

  // grid slength in y direction (unit: meter)
  double ly = 10.0;

  double deltaX ;
  double deltaY;

  bool running;
  bool notifyReset;

  // optimization flags
  bool hasPartPower;
  bool radiative = false;

  // condition flags
  bool convective = true;

  Model2D(this.nx, this.ny) {
    deltaX = lx / nx;  // cell size in x and y
    deltaY = ly / ny;
    t = new Matrix<double> (nx, ny);
    u = new Matrix<double> (nx, ny, 0.0);
    v = new Matrix<double> (nx, ny, 0.0);
   tb = new Matrix<double> (nx,ny);
    q = new Matrix<double> (nx, ny, 0.0);
    conductivity = new Matrix<double> (nx, ny, backgroundConductivity);
    specificHeat = new Matrix<double> (nx, ny, backgroundSpecificHeat);
    density = new Matrix<double> (nx, ny, backgroundDensity);
    fluidity = new Matrix<bool> (nx, ny, true);

    init();


    /*     for (int i=0; i<nx; i++) {
          for (int j=0; j<3; j++) {
              fluidity[i][j] = false;

              conductivity[i][j] = 0.0;

     }}

    for (int i=0; i<3; i++) {
              for (int j=0; j<ny; j++) {
                  fluidity[i][j] = false;
                  fluidity[nx-1-i][j] = false;

                  conductivity[i][j] = 0.0;
                  conductivity[nx-1-i][j] = 0.0;
         }}

*/
      for (int i=0; i<2; i++) {
      for (int j=ny~/2; j<ny; j++) {
                 fluidity[i][j] = false;
                 fluidity[nx-1-i][j] = false;

                 conductivity[i][j] = 0.0;
                 conductivity[nx-1-i][j] = 0.0;
       }
      }
      for (int i=2; i<3; i++) {
            for (int j=ny~/2; j<ny-10; j++) {
                       fluidity[i][j] = false;
                       fluidity[nx-1-i][j] = false;

                       conductivity[i][j] = 0.96;
                       conductivity[nx-1-i][j] = 0.96;
             }
            }

      for (int i=nx~/2; i>=0; i--) {
        for (int j=0; j<i; j++) {
          fluidity[nx~/2-i][j] = false;
          fluidity[nx~/2-1+i][j] = false;

          conductivity[nx~/2-i][j] = 0.15;
          conductivity[nx~/2-1+i][j] = 0.15;
       }
    }

    for (int i= -12; i< 8 ; i++) {
       for (int j = 1; j< 3; j++) {
          fluidity[nx ~/2 + i][ny - j] = false;
       }
     }

    heatSolver = new HeatSolver2D(nx, ny);
    heatSolver.setSpecificHeat(specificHeat);
    heatSolver.setConductivity(conductivity);
    heatSolver.setDensity(density);
    heatSolver.setPower(q);
    heatSolver.setVelocity(u, v);
    heatSolver.setTemperatureBoundary(tb);
    heatSolver.setFluidity(fluidity);

    fluidSolver = new FluidSolver2D(nx, ny);
    fluidSolver.setFluidity(fluidity);
    fluidSolver.setTemperature(t);

    setGridCellSize();

  }

void refreshPowerArray() {

   //      checkPartPower();
           double x, y;
           int count;
           for (int i = 0; i < nx; i++) {
             x = i * deltaX;
             for (int j = 0; j < ny; j++) {
               y = j * deltaY;
               q[i][j] = 0.0;
              /* if (hasPartPower) {
                 count = 0;
                   for (Part p in parts) {
                     if (p.getPower() != 0 && p.getPowerSwitch()) {
                       q[i][j] += p.getPower();
                       count++;
                     }
                   }

                 if (count > 0)
                   q[i][j] /= count;
               } */
             }
           }

         }


  void init() {
    conductivity.fill(backgroundConductivity);
    specificHeat.fill(backgroundSpecificHeat);
    density.fill(backgroundDensity);
    setInitialTemperature();
  }


  void setInitialVelocity() {
    u.fill(0.0);
    v.fill(0.0);

  }


  void setInitialTemperature() {
    t.fill(backgroundTemperature);

  }

/* void checkPartPower() {
       hasPartPower = false;
         for (Part p in parts) {
           if (p.getPower() != 0) {
             hasPartPower = true;
             break;
           }
         }
     }
*/

  void clear() {

    maximumHeatCapacity = -1.0;
  }

  /**
   * Imagine that the 2D plane is thermally coupled with a thin layer that has the background temperature
   */
  void setZHeatDiffusivity(double zHeatDiffusivity) {
    heatSolver.zHeatDiffusivity = zHeatDiffusivity;
  }

  double getZHeatDiffusivity() {
    return heatSolver.zHeatDiffusivity;
  }


  void setGravityType(int gravityType) {
    fluidSolver.setGravityType(gravityType);
  }

  int getGravityType() {
    return fluidSolver.getGravityType();
  }


  void setThermalBuoyancy(double thermalBuoyancy) {
    fluidSolver.setThermalBuoyancy(thermalBuoyancy);
  }

  double getThermalBuoyancy() {
    return fluidSolver.getThermalBuoyancy();
  }


  void setBuoyancyApproximation(int buoyancyApproximation) {
    fluidSolver.setBuoyancyApproximation(buoyancyApproximation);
  }

  int getBuoyancyApproximation() {
    return fluidSolver.getBuoyancyApproximation();
  }


  void setBackgroundViscosity(double viscosity) {
    fluidSolver.setBackgroundViscosity(viscosity);
  }

  double getBackgroundViscosity() {
    return fluidSolver.getViscosity();
  }

  void setGridCellSize() {
    heatSolver.setGridCellSize(deltaX, deltaY);
    fluidSolver.setGridCellSize(deltaX, deltaY);

  }

  ThermalBoundary getThermalBoundary() {
    return heatSolver.getBoundary();
  }

  void setThermalBoundary(ThermalBoundary b) {
    heatSolver.setBoundary(b);
  }


  MassBoundary getMassBoundary() {
    return fluidSolver.getBoundary();
  }

  void setMassBoundary(MassBoundary b) {
    fluidSolver.setBoundary(b);
  }


  void setBackgroundTemperature(double backgroundTemperature) {
    this.backgroundTemperature = backgroundTemperature;
    heatSolver.backgroundTemperature = backgroundTemperature;
  }

  double getBackgroundTemperature() {
    return backgroundTemperature;
  }


  /** return the Prandtl Number of the background fluid */
  double getPrandtlNumber() {
    return getBackgroundViscosity() * backgroundDensity * backgroundSpecificHeat / backgroundConductivity;
  }

  /** get the total thermal energy of the system */
  double getThermalEnergy() {
    double energy = 0.0;
    for (int i = 1; i < nx - 1; i++) { // excluding the border cells to ensure the conservation of energy
      for (int j = 1; j < ny - 1; j++) {
        energy += t[i][j] * density[i][j] * specificHeat[i][j];
      }
    }
    return energy * deltaX * deltaY;
  }


  /** get the total thermal energy stored in this part */
  /** get the thermal energy stored in the cell at the given point. If the point is out of bound, return -1
   * (any impossible value to indicate error) */
  double getThermalEnergyAt(double x, double y) {
    int i = (x / deltaX).round();
    if (i < 0 || i >= nx) return -1.0;
    int j = (y / deltaY).round();
    if (j < 0 || j >= ny) return -1.0;
    return t[i][j] * density[i][j] * specificHeat[i][j] * deltaX * deltaY;
  }

  double getTime() {
    return indexOfStep * heatSolver.getTimeStep();
  }

  int getIndexOfStep() {
    return indexOfStep;
  }

  double getTimeStep() {
    return heatSolver.getTimeStep();
  }

  double getTemperatureAt(double x, double y) {
    int i = min(t.cols - 1, (x / deltaX).round());
    if (i < 0) i = 0;
    int j = min(t.rows - 1, (y / deltaY).round());
    if (j < 0) j = 0;
    return t[i][j];
  }

  double getVorticity(int i, int j) {
    if (i < 1)
      i = 1;
    else if (i > nx - 2)
      i = nx - 2;
    if (j < 1)
      j = 1;
    else if (j > ny - 2)
      j = ny - 2;
    if (!fluidity[i][j])
      return 0.0;
    double du_dy = (u[i][j + 1] - u[i][j - 1]) / deltaY;
    double dv_dx = (v[i + 1][j] - v[i - 1][j]) / deltaX;
    return 0.5 * (du_dy - dv_dx);
  }
  void refreshTemperatureBoundaryArray() {
      double x, y;
      int count;
      for (int i = 0; i < nx; i++) {
        x = i * deltaX;
        for (int j = 0; j < ny; j++) {
          y = j * deltaY;
          tb[i][j] = 0.0;
          count = 0;
          synchronized (parts) {
            for (Part p in parts) {
              if (p.getConstantTemperature())  {
                tb[i][j] += p.getTemperature();
                count++;
              }
            }
          }
          if (count > 0) {
            tb[i][j] /= count;
          } else {
            tb[i][j].isNaN;
          }
        }
      }
    }

  Matrix<double> getStreamFunction() {
    return fluidSolver.getStreamFunction(u, v);
  }

  void nextStep() {

      if (convective) {

        fluidSolver.solve(u, v);
        heatSolver.solve(convective, t);

      }

      indexOfStep++;
    }
}