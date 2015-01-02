
public class DataType {

	public int temp;
	public int humid;
	public int light;
	public long seqid;
	public long time;

	public DataType(int temp, int humid, int light, long seqid, long time) {
		this.temp = temp;
		this.humid = humid;
		this.light = light;
		this.seqid = seqid;
		this.time = time;
	}
	
	public double getPhysicalTemp() {
		int SOT = this.temp & 16383;
		return (-39.6 + 0.01 * SOT);
	}
	
	public double getPhysicalHumid() {
		int SORH = this.humid & 4095;
		double temp = this.getPhysicalTemp();
		double linear = -4 + 0.0405 * SORH - 2.8e-6 * SORH * SORH;
		return ((temp - 25) * (0.01 + 0.00008 * SORH) + linear);
	}
	
	public double getPhysicalLight() {
		return (85 * this.light);
	}
}
