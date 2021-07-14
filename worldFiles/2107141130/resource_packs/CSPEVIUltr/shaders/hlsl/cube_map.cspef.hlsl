#include "ShaderConstants.fxh"
#include "util.fxh"

struct PS_Input
{
    float4 position : SV_Position;
    float2 uv : TEXCOORD_0_FB_MSAA;
    float3 w_pos : CSPE_w_pos;
};

struct PS_Output
{
    float4 color : SV_Target;
};

#include "function_lib.cspe"

float cloudmap(  float2 pos, float qy){

	  float d = 1.0;
	  float nz = 0.0;
	pos *= float2(6.0, 3.0)*1.5;
	pos -= float2(1.0-TIME*0.01, 5.0);
	  float2 np = pos;//float2(pos.y-pos.x, pos.x+pos.y);
	for(float i = 0.0; i < qy; i++){
		nz += noise(np) / (d * (1.0-rain_f*0.3));
		d *= 2.2;
		np *= 2.2;
		np +=  float2(0.04*TIME,TIME*0.04*pow(d, 0.8));
	}
	
	return nz;
}

float warp(float2 p) {

float s = noise(p.xy*float2(50.0,30.0)+float2(TIME*0.0001,TIME*0.0001))*noise(p.xy*float2(60.0,50.0));

return cloudmap(p.xy+float2(s*0.025,s*0.025),6.0);
}

/*
float4 cloudsRender(  float3 w_pos,bool is_water){
float cloud1 =clamp(pow(warp(w_pos.xz)-1.0,0.8)*1.8,0.0,1.0);
float cloud1_sh =clamp(pow(warp(w_pos.xz*0.9)-0.9,1.0)*1.5,0.0,1.0)*0.7;

float4 cloud1_color =lerp(float4(cloud_color.rgb,cloud1),float4(cloud_sh_color.rgb,cloud1_sh),cloud1_sh);

float cloud2 =0.0;
float cloud2_sh =clamp(pow(warp(w_pos.xz*0.87-float2(0.2,0.0)*fog_sunset_f)*0.8,1.0)-0.5,0.0,1.0)*(0.4+fog_sunset_f*0.4+fog_night_f*0.4);

for(float n =0.0;n<10.0;n++){
float cloud_p1 =clamp(pow(warp(w_pos.xz*(0.7+n*0.03))*0.5,5.0),0.0,1.0)*(1.3-n*0.1);
float cloud_sh_p =clamp(pow(warp(w_pos.xz*(0.65+n*0.04))*0.3,5.0)-0.05*n,0.0,1.0)*max(0.8-n*0.2,0.0);
cloud2 += cloud_p1;
cloud2_sh += cloud_sh_p*0.1;
}

float4 cloud2_color=float4(cloud_color.rgb*min(cloud2+0.6,1.0),cloud2);

float3 pos =w_pos*3.0;

  float cloud_sh3,cloud_sh4,sh_m3,sh_m4=0.0;

for(float i = 0.0; i < 5.0; i++){
cloud_sh3 =reduce_b(reduce_a(pos*(0.98-i*0.02-fog_sunset_f*0.01),0.95-i*0.1),0.15+i*0.07);
cloud_sh4 =reduce_b(reduce_a(pos*(0.97-i*0.02-fog_sunset_f*0.01),0.9-i*0.1),0.18+i*0.07);
sh_m3 =max(0.0,max(cloud_sh3,cloud_sh4));
sh_m4 =max(0.0,max(sh_m3,sh_m4));
}

  float cloud3 = reduce_b(reduce_a(pos,1.0),1.0);

float4 cloud3_color;
cloud3_color.rgb =lerp(cloud_color.rgb*0.8,cloud_sh_color.rgb*float3(1.0-sh_m4),sh_m4*2.0);
cloud3_color.a =cloud3;

float4 final_cloud =float4(0.0);

if(CLOUD==1){
final_cloud =cloud1_color;
}
if(CLOUD==2){
final_cloud =cloud2_color;
}
else if(CLOUD==3){
final_cloud =cloud3_color;
}

if(is_water==true){
final_cloud.rgb =cloud_color.rgb;
final_cloud.a *=0.6;
}
else{
final_cloud.a -=pow(fog_f*0.8,3.0);
}

if(UNWATER(FOG_COLOR,rain_f)){
final_cloud =float4(0.0);
}

return final_cloud;
}*/

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
#include "variable.cspe"

float3 dir = -(PSInput.w_pos/(PSInput.w_pos.y-0.15))*0.15;

float3 rd = -PSInput.w_pos;
	rd.x *= length(rd);
	rd.y += 0.15;

fog_f = length(dir.xz);


rain_f =clamp((1.0-pow(FOG_CONTROL.y+0.1,5.0))*2.0,0.0,1.0);
night_f =clamp((0.6-light_f+clamp(0.6-light_f,0.0,1.0))*1.5,0.0,1.0);
sunset_f =clamp((1.0-light_f)*3.0,0.0,clamp(1.0-night_f-rain_f,0.0,1.0));
fog_night_f =pow(clamp(1.0-(FOG_COLOR.r+FOG_COLOR.b)*1.5,0.0,1.0),0.5);
fog_sunset_f =pow(clamp(1.0-(FOG_COLOR.b+FOG_COLOR.g),0.0,clamp(1.0-fog_night_f-rain_f,0.0,1.0)),0.5);

cloud_color =lerp(lerp(cloud_day_color,cloud_sunset_color,fog_sunset_f),cloud_night_color,fog_night_f);
cloud_color = lerp(cloud_color,float4(float3(cloud_color.r+CURRENT_COLOR.r,cloud_color.r+CURRENT_COLOR.r,cloud_color.r+CURRENT_COLOR.r),1.0)*cloud_rain_color,rain_f);

cloud_sh_color =lerp(lerp(cloud_day_sh_color,cloud_sunset_sh_color,fog_sunset_f),cloud_night_sh_color,fog_night_f);
cloud_sh_color = lerp(cloud_sh_color,float4(float3(cloud_sh_color.r,cloud_sh_color.r,cloud_sh_color.r),1.0)*cloud_rain_sh_color,rain_f);


float cloud1 =clamp(pow(warp(dir.xz)-1.0,0.8)*1.8,0.0,1.0);
float cloud1_sh =clamp(pow(warp(dir.xz*0.9)-0.9,1.0)*1.5,0.0,1.0)*0.7;

float4 cloud1_color =lerp(float4(cloud_color.rgb,cloud1),float4(cloud_sh_color.rgb,cloud1_sh),cloud1_sh);

cloud1_color.a=(pow(warp(dir.xz),0.8)-0.8)*1.2-pow(fog_f*0.9,3.0);

//float4 cloud1_color =float4(0.0,0.0,0.0,1.0);

PSOutput.color =cloud1_color;


if(rd.y<0.0){
PSOutput.color.a =0.0;
}

#ifdef WINDOWSMR_MAGICALPHA
    // Set the magic MR value alpha value so that this content pops over layers
    PSOutput.color.a = 133.0f / 255.0f;
#endif
}
