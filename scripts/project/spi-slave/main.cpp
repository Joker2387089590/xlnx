#include <fcntl.h>
#include <unistd.h>

#define SS  252      //定义SS所对应的GPIO接口编号
#define SCLK 253      //定义SCLK所对应的GPIO接口编号
#define MOSI 254      //定义SCLK所对应的GPIO接口编号
#define MISO 255      //定义MISO所对应的GPIO接口编号
#define OUTP 1      //表示GPIO接口方向为输出
#define INP 0       //表示GPIO接口方向为输入



/* SPI端口初始化 */
void spi_init()
{
	set_gpio_direction(SS, OUTP);
	set_gpio_direction(SCLK, OUTP);
	set_gpio_direction(MOSI, OUTP);
	set_gpio_direction(MISO, INP);
	set_gpio_value(SCLK, 0);     //CPOL=0
	set_gpio_value(MOSI, 0);
}
/*
从设备使能
enable：为1时，使能信号有效，SS低电平
为0时，使能信号无效，SS高电平
*/
void ss_enable(int enable)
{
	if (enable)
		set_gpio_value(SS, 0);     //SS低电平，从设备使能有效
	else
		set_gpio_value(SS, 1);     //SS高电平，从设备使能无效
}
 /* SPI字节写 */
void spi_write_byte(unsigned char b)
{
	int i;
	for (i=7; i>=0; i--) {
		set_gpio_value(SCLK, 0);
		set_gpio_value(MOSI, b&(1<<i));   //从高位7到低位0进行串行写入
		delay();       //延时
		set_gpio_value(SCLK, 1);    // CPHA=1，在时钟的第一个跳变沿采样
		delay(); 
	}
}
/* SPI字节读 */
unsigned char spi_read_byte()
{
	int i;
	unsigned char r = 0;
	for (i=0; i<8; i++) {
		set_gpio_value(SCLK, 0);
		delay();       //延时
		set_gpio_value(SCLK, 1);    // CPHA=1，在时钟的第一个跳变沿采样
		r = (r <<1) | get_gpio_value(MISO);   //从高位7到低位0进行串行读出
		delay();
	}
}
/*
 SPI写操作
 buf：写缓冲区
 len：写入字节的长度
*/
void spi_write (unsigned char* buf, int len)
{
	int i;
	spi_init();       //初始化GPIO接口
	ss_enable(1);       //从设备使能有效，通信开始
	delay();        //延时
	//写入数据
	for (i=0; i<len; i++)
		spi_write_byte(buf[i]);
	delay();
	ss_enable(0);       //从设备使能无效，通信结束
}
/*
SPI读操作
buf：读缓冲区
len：读入字节的长度
*/
void spi_read(unsigned char* buf, int len)
{
	int i;
	spi_init();       //初始化GPIO接口
	ss_enable(1);       //从设备使能有效，通信开始
	delay();        //延时
	//读入数据
	for (i=0; i<len; i++)
		buf[i] = spi_read_byte();
	delay();
	ss_enable(0);       //从设备使能无效，通信结束
}