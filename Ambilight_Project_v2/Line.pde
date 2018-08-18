static abstract class lineType {
  static final int VERT = 0;
  static final int AFF  = 1;
}

class Line {
  protected int type;
  protected float m, p; //To use for type AFF
  protected float xValue; //To use for type VERT


  Line() {
    type = lineType.AFF;
    m = 0;
    p = 0;
    xValue = 0;
  }


  Line(float slope, float origin) {
    type = lineType.AFF;
    m = slope;
    p = origin;
    xValue = 0;
  }


  Line(float x) {
    type = lineType.VERT;
    m = 0;
    p = 0;
    xValue = x;
  }


  Void fitTwoPoints(PVector pt1, PVector pt2) {
    if (pt2.x - pt1.x == 0) {
      type = lineType.VERT;
      xValue = pt2.x;
      m=0;
      p=0;
    } else {
      type = lineType.AFF;
      xValue = 0;
      m = (pt2.y - pt1.y) / (pt2.x - pt1.x);
      p = pt1.y - m * pt1.x;
    }

    return null;
  }


  int getType() {
    return type;
  }


  float getSlope() {
    return m;
  }


  float getOrigin() {
    return p;
  }


  float getX() {
    return xValue;
  }


  PVector intersectionWith(Line otherLine) {
    float x, y;

    // No crossing points if the two lines are parralels
    if (this.isParallelTo(otherLine)) {
      return null;
    }


    // If the current line is vertical the x value is already known
    if (type == lineType.VERT) {
      x = xValue;
      y = otherLine.getSlope() * x + otherLine.getOrigin();
      return new PVector(x, y);
    }


    // Same if the other line is vertical
    if (otherLine.getType() == lineType.VERT) {
      x = otherLine.getX();
      y = m * x + p;
      return new PVector(x, y);
    }


    // For all the other cases 
    x = (otherLine.getOrigin() - p) / (m - otherLine.getSlope());
    y = m * x + p;

    return new PVector(x, y);
  }


  boolean isParallelTo(Line otherLine) {
    return (type == lineType.VERT && otherLine.getType() == lineType.VERT) || (m - otherLine.getSlope() == 0 && type == lineType.AFF && otherLine.getType() == lineType.AFF);
  }


  Line[] getBothBisectrix(Line otherLine) { 
    Line[] result = new Line[2];
    float k, m1, p1, m2, p2;

    // If lines are parralels, return the line in the middle
    if (this.isParallelTo(otherLine)) {
      if (type == lineType.VERT) {
        result[0] = new Line((xValue + otherLine.getX())/2);
        result[1] = new Line((xValue + otherLine.getX())/2);
        return result;
      } else {
        result[0] = new Line(m, (p+otherLine.getOrigin())/2);
        result[1] = new Line(m, (p+otherLine.getOrigin())/2);
        return result;
      }
    }

    // If current line is vertical
    if (type == lineType.VERT) {
      m1 = otherLine.getSlope();
      p1 = otherLine.getOrigin();
      k = sqrt(m1*m1+1);
      result[0] = new Line(m1-k, p1 + k * xValue);
      result[1] = new Line(m1+k, p1 - k * xValue);
      return result;
    }

    // If the other line is vertical
    if (otherLine.getType() == lineType.VERT) {
      k = sqrt(m*m+1);
      result[0] = new Line(m-k, p + k * otherLine.getX());
      result[1] = new Line(m+k, p - k * otherLine.getX());
      return result;
    }

    // For the other cases    
    m1 = m;
    p1 = p;
    m2 = otherLine.getSlope();
    p2 = otherLine.getOrigin();

    k = (sqrt(m1*m1+1)/sqrt(m2*m2+1));
    result[0] = new Line((m1-k*m2)/(1-k), (p1-k*p2)/(1-k));
    result[1] = new Line((m1+k*m2)/(1+k), (p1+k*p2)/(1+k));
    return result;
  }


  Line getBisectrixCrossing(Line otherLine, PVector pt1, PVector pt2) {
    Line[] bisectrix;
    float m1, m2, p1, p2, x1, x2;
    bisectrix = getBothBisectrix(otherLine);

    if (bisectrix[0].getType() == lineType.VERT) {
      x1 = bisectrix[0].getX();
      if ((x1 <= pt1.x && x1 >= pt2.x) || (x1 >= pt1.x && x1 <= pt2.x)) {
        return bisectrix[0];
      }
    } else {
      m1 = bisectrix[0].getSlope();
      p1 = bisectrix[0].getOrigin();
      if ((m1*pt1.x+p1 <= pt1.y && m1*pt2.x+p1 >= pt2.y) || (m1*pt1.x+p1 >= pt1.y && m1*pt2.x+p1 <= pt2.y)) {
        return bisectrix[0];
      }
    }

    if (bisectrix[1].getType() == lineType.VERT) {
      x2 = bisectrix[1].getX();
      if ((x2 <= pt1.x && x2 >= pt2.x) || (x2 >= pt1.x && x2 <= pt2.x)) {
        return bisectrix[1];
      }
    } else {
      m2 = bisectrix[1].getSlope();
      p2 = bisectrix[1].getOrigin();
      if ((m2*pt1.x+p2 <= pt1.y && m2*pt2.x+p2 >= pt2.y) || (m2*pt1.x+p2 >= pt1.y && m2*pt2.x+p2 <= pt2.y)) {
        return bisectrix[1];
      }
    }

    return null;
  }


  Line getBisectrix1(Line otherLine) {

    float k, m1, p1, m2, p2;

    // If lines are parralels, return the line in the middle
    if (this.isParallelTo(otherLine)) {
      if (type == lineType.VERT) {
        return new Line((xValue + otherLine.getX())/2);
      } else {
        return new Line(m, (p+otherLine.getOrigin())/2);
      }
    }

    // If current line is vertical
    if (type == lineType.VERT) {
      m1 = otherLine.getSlope();
      p1 = otherLine.getOrigin();
      k = sqrt(m1*m1+1);
      return new Line(m1-k, p1 + k * xValue);
    }

    // If the other line is vertical
    if (otherLine.getType() == lineType.VERT) {
      k = sqrt(m*m+1);
      return new Line(m-k, p + k * otherLine.getX());
    }

    // For the other cases    
    m1 = m;
    p1 = p;
    m2 = otherLine.getSlope();
    p2 = otherLine.getOrigin();

    k = (sqrt(m1*m1+1)/sqrt(m2*m2+1));
    return new Line((m1-k*m2)/(1-k), (p1-k*p2)/(1-k));
  }


  Line getBisectrix2(Line otherLine) {

    float k, m1, p1, m2, p2;

    // If lines are parralels, return the line in the middle
    if (this.isParallelTo(otherLine)) {
      if (type == lineType.VERT) {
        return new Line((xValue + otherLine.getX())/2);
      } else {
        return new Line(m, (p+otherLine.getOrigin())/2);
      }
    }

    // If current line is vertical
    if (type == lineType.VERT) {
      m1 = otherLine.getSlope();
      p1 = otherLine.getOrigin();
      k = sqrt(m1*m1+1);
      return new Line(m1+k, p1 - k * xValue);
    }

    // If the other line is vertical
    if (otherLine.getType() == lineType.VERT) {
      k = sqrt(m*m+1);
      return new Line(m+k, p - k * otherLine.getX());
    }

    // For the other cases    
    m1 = m;
    p1 = p;
    m2 = otherLine.getSlope();
    p2 = otherLine.getOrigin();

    k = (sqrt(m1*m1+1)/sqrt(m2*m2+1));
    return new Line((m1+k*m2)/(1+k), (p1+k*p2)/(1+k));
  }
}
