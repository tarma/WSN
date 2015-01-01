
public class DataType {

	public int temp;
	public int humid;
	public int light;
	public int seqid;
	public long time;

	public DataType(int temp, int humid, int light, int seqid, long time) {
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
		return (-2.0468 + 0.0367 * SORH - 1.5955e-6 * SORH * SORH);
	}
	
	public double getPhysicalLight() {
		return (0.085 * this.light);
	}
}
