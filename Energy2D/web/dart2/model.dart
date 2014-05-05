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

  static const int BUOYANCY_AVERAGE_ALL = 0;
  static const int BUOYANCY_AVERAGE_COLUMN = 1;
  static const int GRAVITY_UNIFORM = 0;
  static const int GRAVITY_CENTRIC = 1;

  int indexOfStep = 0;

  //10 * Constants.AIR_THERMAL_CONDUCTIVITY
  double backgroundConductivity = 0.25;

  //Constants.AIR_SPECIFIC_HEAT
  double backgroundSpecificHeat = 1012.0;

  // Constants.AIR_DENSITY
  double backgroundDensity = 1.204;

  double backgroundTemperature = 10.0;

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


  /*
  List<HeatFluxSensor> heatFluxSensors;
  List<Thermometer> thermometers;
  List<Thermostat> thermostats;
  List<Part> parts;
  List<Anemometer> anemometers;
  List<Photon> photons;
  List<Cloud> clouds;
  List<Tree> trees;
  RaySolver2D raySolver;
  */


  FluidSolver2D fluidSolver;
  HeatSolver2D heatSolver;

  /*
  bool sunny;
  int photonEmissionInterval = 20;
  */


  // number of grid cells
  int nx = 100;
  int ny = 100;

  // grid length in x direction (unit: meter)
  double lx = 10.0;

  // grid slength in y direction (unit: meter)
  double ly = 10.0;

  // cell size in x and y
  double deltaX = 0.1;
  double deltaY = 0.1;

  bool running;
  bool notifyReset;

  // optimization flags
  bool hasPartPower;
  bool radiative = false;

  // condition flags
  bool convective = true;

 /*
  List<PropertyChangeListener> propertyChangeListeners;
  List<ManipulationListener> manipulationListeners;
  Runnable tasks;
 */

  Model2D(this.nx, this.ny) {

    deltaX = lx / nx;
    deltaY = ly / ny;
    t = new Matrix<double> (nx, ny);
    u = new Matrix<double> (nx, ny, 0.0);
    v = new Matrix<double> (nx, ny, 0.0);
    tb = new Matrix<double> (nx, ny, null);
    q = new Matrix<double> (nx, ny, 1.0);
    conductivity = new Matrix<double> (nx, ny, backgroundConductivity);
    specificHeat = new Matrix<double> (nx, ny, backgroundSpecificHeat);
    density = new Matrix<double> (nx, ny, backgroundDensity);
    fluidity = new Matrix<bool> (nx, ny, false);

    for (int i=40; i<50; i++) {
      for (int j=45; j<49; j++) {
        q[i][j] = 100.0;
      }
    }

    /*
    parts = part.add(new Part());
    heatFluxSensors = heatFluxSensors.add(new HeatFluxSensor());
    thermometers = thermometers.add(new Thermometer());
    thermostats = thermostats.add(new Thermostat());
    anemometers = Collections.synchronizedList(new ArrayList<Anemometer>());
    photons = Collections.synchronizedList(new ArrayList<Photon>());
    clouds = Collections.synchronizedList(new ArrayList<Cloud>());
    trees = Collections.synchronizedList(new ArrayList<Tree>());
    */

    init();

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

    /*
    raySolver = new RaySolver2D(lx, ly);
    raySolver.setPower(q);
    */
    setGridCellSize();

    /*
    propertyChangeListeners = new List<PropertyChangeListener>();
    manipulationListeners   = new List<ManipulationListener>();
    */
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
    /*
    for (int i = 0; i < nx; i++) {
      for (int j = 0; j < ny; j++) {
        if (fluidity[i][j]) {
          u[i][j] = v[i][j] = 0.0;
        } else {
          u[i][j] = uWind[i][j];
          v[i][j] = vWind[i][j];
        }
      }
    }
    */
  }


  void setInitialTemperature() {
    t.fill(backgroundTemperature);
    /*
    if (parts == null || parts.isEmpty()) {
      for (int i = 0; i < nx; i++) {
        for (int j = 0; j < ny; j++) {
          t[i][j] = backgroundTemperature;
        }
      }
    }
    else {
      float x, y;
      int count;
      for (int i = 0; i < nx; i++) {
        x = i * deltaX;
        for (int j = 0; j < ny; j++) {
          y = j * deltaY;
          count = 0;
          t[i][j] = 0;
          synchronized (parts) {
            for (Part p : parts) { // a cell gets the average temperature from the overlapping parts
              if (p.getShape().contains(x, y)) {
                count++;
                t[i][j] += p.getTemperature();
              }
            }
          }
          if (count > 0) {
            t[i][j] /= count;
          } else {
            t[i][j] = backgroundTemperature;
          }
        }
      }
    }

    clearSensorData();
    */
  }



  void clear() {
    /*
    parts.clear();
    photons.clear();
    anemometers.clear();
    thermometers.clear();
    heatFluxSensors.clear();
    thermostats.clear();
    clouds.clear();
    trees.clear();
    */
    maximumHeatCapacity = -1.0;
  }



/*
  void setTasks(Runnable r) {
    tasks = r;
  }
*/


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


  /*
  void setSunny(bool sunny) {
    this.sunny = sunny;
    if (sunny) {
      radiative = true;
    } else {
      photons.clear();
    }
  }

  public boolean isSunny() {
    return sunny;
  }

  // synchronize the sun's angle with the clock, assuming sunrise at 6:00 and sunset at 18:00.
  public void moveSun(float sunrise, float sunset) {
    float hour = getTime() / 3600f;
    int i = (int) hour;
    hour += (i % 24) - i;
    raySolver.setSunAngle((hour - sunrise) / (sunset - sunrise) * (float) Math.PI);
    refreshPowerArray();
  }

  public void setSunAngle(float sunAngle) {
    if (Math.abs(sunAngle - raySolver.getSunAngle()) < 0.001f)
      return;
    photons.clear();
    raySolver.setSunAngle(sunAngle);
  }

  public float getSunAngle() {
    return raySolver.getSunAngle();
  }

  public void setSolarPowerDensity(float solarPowerDensity) {
    raySolver.setSolarPowerDensity(solarPowerDensity);
  }

  public float getSolarPowerDensity() {
    return raySolver.getSolarPowerDensity();
  }

  public void setSolarRayCount(int solarRayCount) {
    if (solarRayCount == raySolver.getSolarRayCount())
      return;
    photons.clear();
    raySolver.setSolarRayCount(solarRayCount);
  }

  public int getSolarRayCount() {
    return raySolver.getSolarRayCount();
  }

  public void setSolarRaySpeed(float raySpeed) {
    raySolver.setSolarRaySpeed(raySpeed);
  }

  public float getSolarRaySpeed() {
    return raySolver.getSolarRaySpeed();
  }

  public void setPhotonEmissionInterval(int photonEmissionInterval) {
    this.photonEmissionInterval = photonEmissionInterval;
  }

  public int getPhotonEmissionInterval() {
    return photonEmissionInterval;
  }

  public void addPhoton(Photon p) {
    if (p != null)
      photons.add(p);
  }

  public void removePhoton(Photon p) {
    photons.remove(p);
  }

  public List<Photon> getPhotons() {
    return photons;
  }

  public void addCloud(Cloud c) {
    if (c != null && !clouds.contains(c))
      clouds.add(c);
  }

  public void removeCloud(Cloud c) {
    clouds.remove(c);
  }

  public List<Cloud> getClouds() {
    return clouds;
  }

  public void addTree(Tree t) {
    if (t != null && !trees.contains(t))
      trees.add(t);
  }

  public void removeTree(Tree t) {
    trees.remove(t);
  }

  public List<Tree> getTrees() {
    return trees;
  }
  */

  void setGridCellSize() {
    heatSolver.setGridCellSize(deltaX, deltaY);
    fluidSolver.setGridCellSize(deltaX, deltaY);
    //raySolver.setGridCellSize(deltaX, deltaY);
  }

  /*
  public void setLx(float lx) {
    this.lx = lx;
    deltaX = lx / nx;
    setGridCellSize();
    raySolver.setLx(lx);
  }

  public float getLx() {
    return lx;
  }

  public void setLy(float ly) {
    this.ly = ly;
    deltaY = ly / ny;
    setGridCellSize();
    raySolver.setLy(ly);
  }

  public float getLy() {
    return ly;
  }
  */


  /*
  void translateAllBy(double dx, double dy) {
    if (!thermometers.isEmpty())
      for (Thermometer t in thermometers)
        t.translateBy(dx, dy);
    if (!anemometers.isEmpty())
      for (Anemometer a in anemometers)
        a.translateBy(dx, dy);
    if (!heatFluxSensors.isEmpty())
      for (HeatFluxSensor h in heatFluxSensors)
        h.translateBy(dx, dy);
    if (!clouds.isEmpty())
      for (Cloud c in clouds)
        c.translateBy(dx, dy);
    if (!trees.isEmpty())
      for (Tree t in trees)
        t.translateBy(dx, dy);
    for (Part p in parts)
      p.translateBy(dx, dy);
  }

  boolean scaleAll(double scale) {
    Rectangle2D.Float bound = new Rectangle2D.Float(0, 0, lx, ly);
    bool out = false;
    if (!thermometers.isEmpty())
      for (Thermometer t in thermometers) {
        t.setCenter(scale * t.getX(), ly - scale * (ly - t.getY()));
        if (!bound.intersects(t.getShape().getBounds2D()))
          out = true;
      }
    if (!anemometers.isEmpty())
      for (Anemometer a in anemometers) {
        a.setCenter(scale * a.getX(), ly - scale * (ly - a.getY()));
        if (!bound.intersects(a.getShape().getBounds2D()))
          out = true;
      }
    if (!heatFluxSensors.isEmpty())
      for (HeatFluxSensor h in heatFluxSensors) {
        h.setCenter(scale * h.getX(), ly - scale * (ly - h.getY()));
        if (!bound.intersects(h.getShape().getBounds2D()))
          out = true;
      }

    if (!clouds.isEmpty())
      for (Cloud c in clouds) {
        c.setLocation(scale * c.getX(), ly - scale * (ly - c.getY()));
        c.setDimension(c.getWidth() * scale, c.getHeight() * scale);
        if (!bound.intersects(c.getShape().getBounds2D()))
          out = true;
      }
    if (!trees.isEmpty())
      for (Tree t in trees) {
        t.setLocation(scale * t.getX(), ly - scale * (ly - t.getY()));
        t.setDimension(t.getWidth() * scale, t.getHeight() * scale);
        if (!bound.intersects(t.getShape().getBounds2D()))
          out = true;
      }

    for (Part p in parts) {
      Shape s = p.getShape();
      if (s is Rectangle2D.Float) {
        Rectangle2D.Float r = (Rectangle2D.Float) s;
        r.x = scale * r.x;
        r.y = ly - scale * (ly - r.y);
        r.width *= scale;
        r.height *= scale;
        if (!bound.intersects(r))
          out = true;
      } else if (s is Ellipse2D.Float) {
        Ellipse2D.Float e = (Ellipse2D.Float) s;
        e.x = scale * e.x;
        e.y = ly - scale * (ly - e.y);
        e.width *= scale;
        e.height *= scale;
        if (!bound.intersects(e.getBounds2D()))
          out = true;
      } else if (s is Ring2D) {
        Ring2D a = (Ring2D) s;
        float x = scale * a.getX();
        float y = ly - scale * (ly - a.getY());
        float innerDiameter = a.getInnerDiameter() * scale;
        float outerDiameter = a.getOuterDiameter() * scale;
        a.setRing(x, y, innerDiameter, outerDiameter);
        if (!bound.intersects(a.getBounds2D()))
          out = true;
      } else if (s is Polygon2D) {
        Polygon2D g = (Polygon2D) s;
        int n = g.getVertexCount();
        for (int i = 0; i < n; i++) {
          Point2D.Float h = g.getVertex(i);
          h.x = scale * h.x;
          h.y = ly - scale * (ly - h.y);
        }
        if (!bound.intersects(g.getBounds2D()))
          out = true;
      }
    }
    return out;
  }
  */


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

  /* thermostats

  // only one thermostat is needed for a power source or to connect a thermometer and a power source
  Thermostat addThermostat(Thermometer t, Part p) {
    Iterator<Thermostat> i = thermostats.iterator();
    synchronized (thermostats) {
      while (i.hasNext()) {
        Thermostat x = i.next();
        if (x.getThermometer() == t && x.getPowerSource() == p)
          return x;
      }
    }
    Thermostat x = new Thermostat(t, p);
    thermostats.add(x);
    return x;
  }

  void removeThermostat(Thermometer t, Part p) {
    if (thermostats.isEmpty())
      return;
    synchronized (thermostats) {
      for (Iterator<Thermostat> i = thermostats.iterator(); i.hasNext();) {
        Thermostat x = i.next();
        if (x.getThermometer() == t && x.getPowerSource() == p)
          i.remove();
      }
    }
  }

  bool isConnected(Thermometer t, Part p) {
    Iterator<Thermostat> i = thermostats.iterator();
    synchronized (thermostats) {
      while (i.hasNext()) {
        Thermostat x = i.next();
        if (x.getThermometer() == t && x.getPowerSource() == p)
          return true;
      }
    }
    return false;
  }


  Thermostat getThermostat(Object o) {
    Iterator<Thermostat> i = thermostats.iterator();
    synchronized (thermostats) {
      while (i.hasNext()) {
        Thermostat x = i.next();
        if (x.getThermometer() == o || x.getPowerSource() == o)
          return x;
      }
    }
    return null;
  }

  public Thermostat getThermostat(Thermometer t, Part p) {
    Iterator<Thermostat> i = thermostats.iterator();
    synchronized (thermostats) {
      while (i.hasNext()) {
        Thermostat x = i.next();
        if (x.getThermometer() == t && x.getPowerSource() == p)
          return x;
      }
    }
    return null;
  }

   List<Thermostat> getThermostats() {
    return thermostats;
  }

  // thermometers

   void addThermometer(Thermometer t) {
    thermometers.add(t);
  }

   void addThermometer(double x, double y) {
    thermometers.add(new Thermometer(x, y));
  }

   void addThermometer(double x, double y, String uid, String label, int stencil) {
    Thermometer t = new Thermometer(x, y);
    t.setUid(uid);
    t.setLabel(label);
    t.setStencil(stencil);
    thermometers.add(t);
  }

   void removeThermometer(Thermometer t) {
    thermometers.remove(t);
    if (!thermostats.isEmpty()) {
      Iterator<Thermostat> i = thermostats.iterator();
      while (i.hasNext()) {
        Thermostat x = i.next();
        if (x.getThermometer() == t)
          i.remove();
      }
    }
  }

   List<Thermometer> getThermometers() {
    return thermometers;
  }

   Thermometer getThermometer(String uid) {
    if (uid == null)
      return null;
    synchronized (thermometers) {
      for (Thermometer t in thermometers) {
        if (uid.equals(t.getUid()))
          return t;
      }
    }
    return null;
  }

   Thermometer getThermometer(int i) {
    if (i < 0 || i >= thermometers.size())
      return null;
    return thermometers.get(i);
  }

  // anemometers

   void addAnemometer(Anemometer a) {
    anemometers.add(a);
  }

   void addAnemometer(double x, double y) {
    anemometers.add(new Anemometer(x, y));
  }

   void addAnemometer(double x, double y, String uid, String label, int stencil) {
    Anemometer a = new Anemometer(x, y);
    a.setUid(uid);
    a.setLabel(label);
    a.setStencil(stencil);
    anemometers.add(a);
  }

   void removeAnemometer(Anemometer a) {
    anemometers.remove(a);
  }

   List<Anemometer> getAnemometers() {
    return anemometers;
  }

   Anemometer getAnemometer(String uid) {
    if (uid == null)
      return null;
    synchronized (anemometers) {
      for (Anemometer a in anemometers) {
        if (uid.equals(a.getUid()))
          return a;
      }
    }
    return null;
  }

   Anemometer getAnemometer(int i) {
    if (i < 0 || i >= anemometers.size())
      return null;
    return anemometers.get(i);
  }

  // heat flux sensors

   void addHeatFluxSensor(HeatFluxSensor h) {
    heatFluxSensors.add(h);
  }

   void addHeatFluxSensor(double x, double y) {
    heatFluxSensors.add(new HeatFluxSensor(x, y));
  }

   void addHeatFluxSensor(double x, double y, String uid, String label, double angle) {
    HeatFluxSensor h = new HeatFluxSensor(x, y);
    h.setUid(uid);
    h.setLabel(label);
    h.setAngle(angle);
    heatFluxSensors.add(h);
  }

   void removeHeatFluxSensor(HeatFluxSensor h) {
    heatFluxSensors.remove(h);
  }

   List<HeatFluxSensor> getHeatFluxSensors() {
    return heatFluxSensors;
  }

   HeatFluxSensor getHeatFluxSensor(String uid) {
    if (uid == null)
      return null;
    synchronized (heatFluxSensors) {
      for (HeatFluxSensor h in heatFluxSensors) {
        if (uid.equals(h.getUid()))
          return h;
      }
    }
    return null;
  }

   HeatFluxSensor getHeatFluxSensor(int i) {
    if (i < 0 || i >= heatFluxSensors.size())
      return null;
    return heatFluxSensors.get(i);
  }

  // Since the sensor data are erased, the index of step (and hence the clock) is also reset.
   void clearSensorData() {
    Matrix<double> bounds;
    indexOfStep = 0;
    if (!thermometers.isEmpty()) {
      synchronized (thermometers) {
        for (Thermometer t in thermometers) {
          t.clear();
        }
      }
    }
    if (!anemometers.isEmpty()) {
      synchronized (anemometers) {
        for (Anemometer a in anemometers) {
          a.clear();
        }
      }
    }
    if (!heatFluxSensors.isEmpty()) {
      synchronized (heatFluxSensors) {
        for (HeatFluxSensor h in heatFluxSensors) {
          h.clear();
        }
      }
    }
  }

   Matrix<double> getSensorDataBounds(int type) {
    switch (type) {
    case 0:
      if (!thermometers.isEmpty()) {
        bounds = new Matrix<double> (Float.MAX_VALUE, -Float.MAX_VALUE );
        float min, max;
        synchronized (thermometers) {
          for (Thermometer t in thermometers) {
            min = t.getDataMinimum();
            if (Float.isNaN(min)) // no data has been collected
              return null;
            max = t.getDataMaximum();
            if (bounds[0] > min)
              bounds[0] = min;
            if (bounds[1] < max)
              bounds[1] = max;
          }
        }
        return bounds;
      }
      break;
    case 1:
      if (!heatFluxSensors.isEmpty()) {
        bounds = new Matrix<double> (Float.MAX_VALUE, -Float.MAX_VALUE);
        float min, max;
        synchronized (heatFluxSensors) {
          for (HeatFluxSensor f in heatFluxSensors) {
            min = f.getDataMinimum();
            if (Float.isNaN(min)) // no data has been collected
              return null;
            max = f.getDataMaximum();
            if (bounds[0] > min)
              bounds[0] = min;
            if (bounds[1] < max)
              bounds[1] = max;
          }
        }
        return bounds;
      }
      break;
    case 2:
      if (!anemometers.isEmpty()) {
        Matrix<double> bounds = new Matrix<double> ( Float.MAX_VALUE, -Float.MAX_VALUE );
        float min, max;
        synchronized (anemometers) {
          for (Anemometer a in anemometers) {
            min = a.getDataMinimum();
            if (Float.isNaN(min)) // no data has been collected
              return null;
            max = a.getDataMaximum();
            if (bounds[0] > min)
              bounds[0] = min;
            if (bounds[1] < max)
              bounds[1] = max;
          }
        }
        return bounds;
      }
      break;
    }
    return null; // no sensor
  }
  */

 /*
 Part addRectangularPart(double x, double y, double w, double h) {
    Part p = new Part(new Rectangle2D.double(x, y, w, h));
    addPart(p);
    return p;
  }

  Part addRectangularPart(double x, double y, double w, double h, double t) {
    Part p = addRectangularPart(x, y, w, h);
    p.setTemperature(t);
    return p;
  }

  Part addEllipticalPart(double x, double y, double a, double b) {
    Part p = new Part(new Ellipse2D.double(x - 0.5f * a, y - 0.5f * b, a, b));
    addPart(p);
    return p;
  }

   Part addEllipticalPart(double x, double y, double a, double b, double t) {
    Part p = addEllipticalPart(x, y, a, b);
    p.setTemperature(t);
    return p;
  }

   Part addRingPart(double x, double y, double inner, double outer) {
    Part p = new Part(new Ring2D(x, y, inner, outer));
    addPart(p);
    return p;
  }

   Part addPolygonPart(Matrix<double> x, Matrix<double> y) {
    Part p = new Part(new Polygon2D(x, y));
    addPart(p);
    return p;
  }
   Part addPolygonPart(Matrix<double> x, Matrix<double> y, double t) {
    Part p = addPolygonPart(x, y);
    p.setTemperature(t);
    return p;
  }

   Part addBlobPart(Matrix<double> x, Matrix<double> y) {
    Part p = new Part(new Blob2D(x, y));
    addPart(p);
    return p;
  }

   Part addBlobPart(Matrix<double> x, Matrix<double> y, double t) {
    Part p = addBlobPart(x, y);
    p.setTemperature(t);
    return p;
  }

  List<Part> getParts() {
    return parts;
  }

  Part getPart(String uid) {
    if (uid == null)
      return null;
    synchronized (parts) {
      for (Part p in parts) {
        if (uid.equals(p.getUid()))
          return p;
      }
    }
    return null;
  }

  // Every manipulable has a UID. To avoid confusion, two objects of different types cannot have the same UID.
  bool isUidUsed(String uid) {
    if (uid == null || uid.trim().equals(""))
      throw new IllegalArgumentException("UID cannot be null or an empty string.");
    synchronized (parts) {
      for (Part p in parts) {
        if (uid.equals(p.getUid()))
          return true;
      }
    }
    synchronized (thermometers) {
      for (Thermometer t in thermometers) {
        if (uid.equals(t.getUid()))
          return true;
      }
    }
    synchronized (anemometers) {
      for (Anemometer a in anemometers) {
        if (uid.equals(a.getUid()))
          return true;
      }
    }
    synchronized (heatFluxSensors) {
      for (HeatFluxSensor h in heatFluxSensors) {
        if (uid.equals(h.getUid()))
          return true;
      }
    }
    return false;
  }

  Part getPart(int i) {
    if (i < 0 || i >= parts.size())
      return null;
    return parts.get(i);
  }

  int getPartCount() {
    return parts.size();
  }

  void addPart(Part p) {
    if (!parts.contains(p)) {
      parts.add(p);
      if (p.getPower() != 0)
        hasPartPower = true;
      if (p.getEmissivity() > 0)
        radiative = true;
    }
  }

  void removePart(Part p) {
    parts.remove(p);
    if (!thermostats.isEmpty()) {
      Iterator<Thermostat> i = thermostats.iterator();
      while (i.hasNext()) {
        Thermostat x = i.next();
        if (x.getPowerSource() == p)
          i.remove();
      }
    }
    checkPartPower();
    checkPartRadiation();
  }
  */


  // the part on the top sets the properties of a cell
  /*
   void refreshMaterialPropertyArrays() {
    Part p = null;
    int count = parts.size();
    double x, y, windSpeed = 0;
    bool initial = indexOfStep == 0;
    maximumHeatCapacity = backgroundDensity * backgroundSpecificHeat;
    double heatCapacity = 0;
    for (int i = 0; i < nx; i++) {
      x = i * deltaX;
      for (int j = 0; j < ny; j++) {
        y = j * deltaY;
        conductivity[i][j] = backgroundConductivity;
        specificHeat[i][j] = backgroundSpecificHeat;
        density[i][j] = backgroundDensity;
        fluidity[i][j] = true;
        uWind[i][j] = vWind[i][j] = 0;
        synchronized (parts) {
          ListIterator<Part> li = parts.listIterator(count);
          while (li.hasPrevious()) {
            p = li.previous();
            if (p.getShape().contains(x, y)) {
              conductivity[i][j] = p.getThermalConductivity();
              specificHeat[i][j] = p.getSpecificHeat();
              density[i][j] = p.getDensity();
              if (!initial && p.getConstantTemperature())
                t[i][j] = p.getTemperature();
              fluidity[i][j] = false;
              if ((windSpeed = p.getWindSpeed()) != 0) {
                uWind[i][j] = (float) (windSpeed * Math.cos(p.getWindAngle()));
                vWind[i][j] = (float) (windSpeed * Math.sin(p.getWindAngle()));
              }
              break;
            }
          }
        }
        heatCapacity = specificHeat[i][j] * density[i][j];
        if (maximumHeatCapacity < heatCapacity)
          maximumHeatCapacity = heatCapacity;
      }
    }
    if (initial) {
      setInitialTemperature();
      setInitialVelocity();
    }
  }

   void refreshPowerArray() {
    checkPartPower();
    float x, y;
    int count;
    for (int i = 0; i < nx; i++) {
      x = i * deltaX;
      for (int j = 0; j < ny; j++) {
        y = j * deltaY;
        q[i][j] = 0;
        if (hasPartPower) {
          count = 0;
          synchronized (parts) {
            for (Part p in parts) {
              if (p.getPower() != 0 && p.getPowerSwitch() && p.getShape().contains(x, y)) {
                q[i][j] += p.getPower();
                count++;
              }
            }
          }
          if (count > 0)
            q[i][j] /= count;
        }
      }
    }
  }
 */
  /*
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
            if (p.getConstantTemperature() && p.getShape().contains(x, y)) {
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
*/


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

   /*
   double getThermalEnergy(Part p) {
    if (p == null)
      return 0;
    float x, y;
    float energy = 0;
    for (int i = 0; i < nx; i++) {
      x = i * deltaX;
      for (int j = 0; j < ny; j++) {
        y = j * deltaY;
        if (p.getShape().contains(x, y)) { // no overlap of parts will be allowed
          energy += t[i][j] * density[i][j] * specificHeat[i][j];
        }
      }
    }
    return energy * deltaX * deltaY;
  }
  */


  /** get the thermal energy stored in the cell at the given point. If the point is out of bound, return -1
   * (any impossible value to indicate error) */
  double getThermalEnergyAt(double x, double y) {
    int i = (x / deltaX).round();
    if (i < 0 || i >= nx) return -1.0;
    int j = (y / deltaY).round();
    if (j < 0 || j >= ny) return -1.0;
    return t[i][j] * density[i][j] * specificHeat[i][j] * deltaX * deltaY;
  }


  /*
  public void run() {
    checkPartPower();
    checkPartRadiation();
    refreshPowerArray();
    if (!running) {
      running = true;
      while (running) {
        nextStep();
        if (fatalErrorOccurred()) {
          notifyManipulationListeners(ManipulationEvent.STOP);
          notifyManipulationListeners(ManipulationEvent.FATAL_ERROR_OCCURRED);
          break;
        }
        if (tasks != null)
          tasks.run();
      }
      if (notifyReset) {
        indexOfStep = 0;
        reallyReset();
        notifyReset = false;
        // call view.repaint() to get rid of the residual pixels that are still calculated in nextStep()
        notifyManipulationListeners(ManipulationEvent.REPAINT);
      }
    }
  }

  bool fatalErrorOccurred() {
    return int.isNaN(t[nx / 2][ny / 2]);
  }

  void stop() {
    running = false;
  }

  bool isRunning() {
    return running;
  }

  void reset() {
    if (running) {
      stop();
      notifyReset = true;
    } else {
      reallyReset();
    }
    running = false;
    indexOfStep = 0;
  }

  void reallyReset() {
    setInitialTemperature();
    setInitialVelocity();
    for (Part p in parts)
      p.setPowerSwitch(true);
    if (!anemometers.isEmpty())
      for (Anemometer a in anemometers)
        a.setAngle(0);
    photons.clear();
    heatSolver.reset();
    fluidSolver.reset();
  }
  private void checkPartPower() {
    hasPartPower = false;
    synchronized (parts) {
      for (Part p : parts) {
        if (p.getPower() != 0) {
          hasPartPower = true;
          break;
        }
      }
    }
  }

  private void checkPartRadiation() {
    radiative = sunny;
    if (!radiative) {
      synchronized (parts) {
        for (Part p : parts) {
          if (p.getEmissivity() > 0) {
            radiative = true;
            break;
          }
        }
      }
    }
  }
  */


  void nextStep() {
    /*
    // ray solver
    if (radiative) {
      if (indexOfStep % photonEmissionInterval == 0) {
        refreshPowerArray();
        if (sunny)
          raySolver.sunShine(photons, parts);
        raySolver.radiate(this);
      }
      raySolver.solve(this);
    }
    */

    if (convective) {
      //fluidSolver.solve(u, v);
      heatSolver.solve(convective, t);

      /*
      if (!clouds.isEmpty()) {
        synchronized (clouds) {
          for (Cloud c : clouds)
            c.move(heatSolver.getTimeStep(), lx);
          }
        }
      }
      */
    }
    indexOfStep++;
  }


  double getTime() {
    return indexOfStep * heatSolver.getTimeStep();
  }

  int getIndexOfStep() {
    return indexOfStep;
  }

  /*
  void setTimeStep(double timeStep) {
    notifyPropertyChangeListeners("Time step", getTimeStep(), timeStep);
    heatSolver.setTimeStep(timeStep);
    fluidSolver.setTimeStep(timeStep);
  }
*/

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

  /*
  public float getTemperature(int i, int j, byte stencil) {
    if (i < 0) {
      i = 0;
    } else if (i > nx - 1) {
      i = nx - 1;
    }

    if (j < 0) {
      j = 0;
    } else if (j > ny - 1) {
      j = ny - 1;
    }
    switch (stencil) {
    case Sensor.ONE_POINT:
      return t[i][j];
    case Sensor.FIVE_POINT:
      float temp = t[i][j];
      int count = 1;
      if (i > 0) {
        temp += t[i - 1][j];
        count++;
      }
      if (i < nx - 1) {
        temp += t[i + 1][j];
        count++;
      }
      if (j > 0) {
        temp += t[i][j - 1];
        count++;
      }
      if (j < ny - 1) {
        temp += t[i][j + 1];
        count++;
      }
      return temp / count;
    case Sensor.NINE_POINT:
      temp = t[i][j];
      count = 1;
      if (i > 0) {
        temp += t[i - 1][j];
        count++;
      }
      if (i < nx - 1) {
        temp += t[i + 1][j];
        count++;
      }
      if (j > 0) {
        temp += t[i][j - 1];
        count++;
      }
      if (j < ny - 1) {
        temp += t[i][j + 1];
        count++;
      }
      if (i > 0 && j > 0) {
        temp += t[i - 1][j - 1];
        count++;
      }
      if (i > 0 && j < ny - 1) {
        temp += t[i - 1][j + 1];
        count++;
      }
      if (i < nx - 1 && j > 0) {
        temp += t[i + 1][j - 1];
        count++;
      }
      if (i < nx - 1 && j < ny - 1) {
        temp += t[i + 1][j + 1];
        count++;
      }
      return temp / count;
    default:
      return t[i][j];
    }
  }


  public void setTemperatureAt(float x, float y, float temperature) {
    int i = Math.min(t.length - 1, Math.round(x / deltaX));
    if (i < 0)
      return;
    int j = Math.min(t[0].length - 1, Math.round(y / deltaY));
    if (j < 0)
      return;
    t[i][j] = temperature;
  }

  public void changeTemperatureAt(float x, float y, float increment) {
    int i = Math.min(t.length - 1, Math.round(x / deltaX));
    if (i < 0)
      return;
    int j = Math.min(t[0].length - 1, Math.round(y / deltaY));
    if (j < 0)
      return;
    t[i][j] += increment;
  }

  float getAverageTemperatureAt(float x, float y) {
    float temp = 0;
    int i0 = Math.round(x / deltaX);
    int j0 = Math.round(y / deltaY);
    int i = Math.min(t.length - 1, i0);
    int j = Math.min(t[0].length - 1, j0);
    if (i < 0)
      i = 0;
    if (j < 0)
      j = 0;
    temp += t[i][j];
    i = Math.min(t.length - 1, i0 + 1);
    j = Math.min(t[0].length - 1, j0);
    if (i < 0)
      i = 0;
    if (j < 0)
      j = 0;
    temp += t[i][j];
    i = Math.min(t.length - 1, i0 - 1);
    j = Math.min(t[0].length - 1, j0);
    if (i < 0)
      i = 0;
    if (j < 0)
      j = 0;
    temp += t[i][j];
    i = Math.min(t.length - 1, i0);
    j = Math.min(t[0].length - 1, j0 + 1);
    if (i < 0)
      i = 0;
    if (j < 0)
      j = 0;
    temp += t[i][j];
    i = Math.min(t.length - 1, i0);
    j = Math.min(t[0].length - 1, j0 - 1);
    if (i < 0)
      i = 0;
    if (j < 0)
      j = 0;
    temp += t[i][j];
    return temp * 0.2f;
  }

  void changeAverageTemperatureAt(float x, float y, float increment) {
    increment *= 0.2f;
    int i0 = Math.round(x / deltaX);
    int j0 = Math.round(y / deltaY);
    int i = Math.min(t.length - 1, i0);
    int j = Math.min(t[0].length - 1, j0);
    if (i >= 0 && j >= 0)
      t[i][j] += increment;
    i = Math.min(t.length - 1, i0 + 1);
    j = Math.min(t[0].length - 1, j0);
    if (i >= 0 && j >= 0)
      t[i][j] += increment;
    i = Math.min(t.length - 1, i0 - 1);
    j = Math.min(t[0].length - 1, j0);
    if (i >= 0 && j >= 0)
      t[i][j] += increment;
    i = Math.min(t.length - 1, i0);
    j = Math.min(t[0].length - 1, j0 + 1);
    if (i >= 0 && j >= 0)
      t[i][j] += increment;
    i = Math.min(t.length - 1, i0);
    j = Math.min(t[0].length - 1, j0 - 1);
    if (i >= 0 && j >= 0)
      t[i][j] += increment;
  }

  public float[][] getTemperature() {
    return t;
  }

  public float[] getHeatFlux(int i, int j) {
    if (i < 1)
      i = 1;
    else if (i > nx - 2)
      i = nx - 2;
    if (j < 1)
      j = 1;
    else if (j > ny - 2)
      j = ny - 2;
    float fx = -conductivity[i][j] * (t[i + 1][j] - t[i - 1][j]) / (2 * deltaX);
    float fy = -conductivity[i][j] * (t[i][j + 1] - t[i][j - 1]) / (2 * deltaY);
    return new float[] { fx, fy };
  }

  public float[] getHeatFluxAt(float x, float y) {
    return getHeatFlux(Math.round(x / deltaX), Math.round(y / deltaY));
  }

  public float[][] getXVelocity() {
    return u;
  }

  public float[][] getYVelocity() {
    return v;
  }

  public float[] getVelocityAt(float x, float y) {
    int i = Math.min(t.length - 1, Math.round(x / deltaX));
    if (i < 0)
      i = 0;
    int j = Math.min(t[0].length - 1, Math.round(y / deltaY));
    if (j < 0)
      j = 0;
    return new float[] { u[i][j], v[i][j] };
  }

  public float getVorticityAt(float x, float y) {
    return getVorticity(Math.round(x / deltaX), Math.round(y / deltaY));
  }
*/


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

/*
  double getVorticity(int i, int j, int stencil) {
    switch (stencil) {
    case Sensor.FIVE_POINT:
      float vor = getVorticity(i, j);
      vor += getVorticity(i - 1, j);
      vor += getVorticity(i + 1, j);
      vor += getVorticity(i, j - 1);
      vor += getVorticity(i, j + 1);
      return vor / 5;
    case Sensor.NINE_POINT:
      vor = getVorticity(i, j);
      vor += getVorticity(i - 1, j);
      vor += getVorticity(i + 1, j);
      vor += getVorticity(i, j - 1);
      vor += getVorticity(i, j + 1);
      vor += getVorticity(i - 1, j - 1);
      vor += getVorticity(i - 1, j + 1);
      vor += getVorticity(i + 1, j - 1);
      vor += getVorticity(i + 1, j + 1);
      return vor / 9;
    default:
      return getVorticity(i, j);
    }
  }
*/

  Matrix<double> getStreamFunction() {
    return fluidSolver.getStreamFunction(u, v);
  }

  /*
  bool hasSensor() {
    return !thermometers.isEmpty() || !heatFluxSensors.isEmpty() || !anemometers.isEmpty();
  }

  public void takeMeasurement() {
    if (!thermometers.isEmpty()) {
      int i, j;
      int offset = Math.round(thermometers.get(0).getSensingSpotY() / ly * ny);
      synchronized (thermometers) {
        for (Thermometer m : thermometers) {
          i = Math.round(m.getX() / deltaX);
          j = Math.round(m.getY() / deltaY);
          if (i >= 0 && i < nx && j >= 0 && j < ny) {
            m.addData(getTime(), getTemperature(i, j + offset, m.getStencil()));
          }
        }
      }
    }
    if (!heatFluxSensors.isEmpty()) {
      int i, j;
      synchronized (heatFluxSensors) {
        for (HeatFluxSensor f : heatFluxSensors) {
          i = Math.round(f.getX() / deltaX);
          j = Math.round(f.getY() / deltaY);
          if (i >= 0 && i < nx && j >= 0 && j < ny) {
            float[] h = getHeatFlux(i, j);
            f.addData(getTime(), (float) (h[0] * Math.sin(f.getAngle()) + h[1] * Math.cos(f.getAngle())));
          }
        }
      }
    }
    if (!anemometers.isEmpty()) {
      int i, j;
      synchronized (anemometers) {
        for (Anemometer a : anemometers) {
          i = Math.round(a.getX() / deltaX);
          j = Math.round(a.getY() / deltaY);
          if (i >= 0 && i < nx && j >= 0 && j < ny) {
            a.addData(getTime(), (float) Math.hypot(u[i][j], v[i][j]));
          }
        }
      }
    }
  }

  // if controllers run every step, they could slow down significantly
  public void control() {
    boolean refresh = false;
    for (Thermostat x : thermostats) {
      if (x.onoff(this))
        refresh = true;
    }
    if (refresh)
      refreshPowerArray();
  }

  public void addPropertyChangeListener(PropertyChangeListener listener) {
    if (!propertyChangeListeners.contains(listener))
      propertyChangeListeners.add(listener);
  }

  public void removePropertyChangeListener(PropertyChangeListener listener) {
    if (listener != null)
      propertyChangeListeners.remove(listener);
  }

  private void notifyPropertyChangeListeners(String propertyName, Object oldValue, Object newValue) {
    if (propertyChangeListeners.isEmpty())
      return;
    PropertyChangeEvent e = new PropertyChangeEvent(this, propertyName, oldValue, newValue);
    for (PropertyChangeListener x : propertyChangeListeners)
      x.propertyChange(e);
  }

  public void addManipulationListener(ManipulationListener listener) {
    if (!manipulationListeners.contains(listener))
      manipulationListeners.add(listener);
  }

  public void removeManipulationListener(ManipulationListener listener) {
    if (listener != null)
      manipulationListeners.remove(listener);
  }

  private void notifyManipulationListeners(byte type) {
    if (manipulationListeners.isEmpty())
      return;
    ManipulationEvent e = new ManipulationEvent(this, type);
    for (ManipulationListener x : manipulationListeners)
      x.manipulationOccured(e);
  }

}
*/
}