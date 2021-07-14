#include "ShaderConstants.fxh"

struct PS_Input
{
    float4 position : SV_Position;
    float4 color : COLOR;
    float3 w_pos : CSPE_w_pos;
};

struct PS_Output
{
    float4 color : SV_Target;
};

#include "function_lib.cspe"
/*
float4 skyRender(float3 w_pos){

float3 c_pos =float3(w_pos.x,w_pos.y+1.0-fog_sunset_f*0.5,w_pos.z);
  float3 np = normalize(c_pos);
  float sun = abs(1.0-length(np.yz));

  float sky_a =length(w_pos);

float4 sky_color;


sky_color=lerp(skytop_color, sky_far, pow(clamp(sky_a*(2.0-fog_sunset_f*0.2),0.0,1.0),1.2+fog_sunset_f*0.5));
sky_color=lerp(sky_color, sfog_color,pow(clamp(sky_a*1.7,0.0,1.0),1.5+fog_sunset_f*0.5));

sky_color +=sun*sfog_color*(1.0-fog_night_f)*7.0;
#ifdef STAR
sky_color =lerp(sky_color,stars_color,starRender( w_pos.xz*1000.0, 0.99)*fog_night_f*(1.0-rain_f));
#endif

sky_color.rgb =toneMap(sky_color.rgb,0.65);

#ifdef UN_SH_LIGHT
sky_color.rgb +=un_sh_light*0.2;
#endif

sky_color=lerp(sky_color, FOG_COLOR,clamp(pow(sky_a*(1.05),3.0-fog_sunset_f*2.0),0.0,1.0));

if(UNWATER(FOG_COLOR,rain_f)){
sky_color =FOG_COLOR;
}

return sky_color;
}*/


ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
#include "variable.cspe"

rain_f =clamp((1.0-pow(FOG_CONTROL.y+0.1,5.0))*2.0,0.0,1.0);
night_f =clamp((0.6-light_f+clamp(0.6-light_f,0.0,1.0))*1.5,0.0,1.0);
sunset_f =clamp((1.0-light_f)*3.0,0.0,clamp(1.0-night_f-rain_f,0.0,1.0));
fog_night_f =pow(clamp(1.0-(FOG_COLOR.r+FOG_COLOR.b)*1.5,0.0,1.0),0.5);
fog_sunset_f =pow(clamp(1.0-(FOG_COLOR.b+FOG_COLOR.g),0.0,clamp(1.0-fog_night_f-rain_f,0.0,1.0)),0.5);





un_sh_light = clamp(1.0-pow(FOG_COLOR.r*1.5,5.0)-fog_sunset_f-fog_night_f,0.0,1.0);

w_light_color = lerp(lerp(day_color,sunset_color,sunset_f),night_color,night_f);
w_light_color = lerp(w_light_color,float4(float3(w_light_color.b+night_f*0.5,w_light_color.b+night_f*0.5,w_light_color.b+night_f*0.5),1.0)*rain_color,rain_f);

skytop_color =lerp(lerp(sky_day_color,sky_sunset_color,fog_sunset_f),sky_night_color,fog_night_f);
skytop_color = lerp(skytop_color,float4(float3(skytop_color.r+CURRENT_COLOR.r,skytop_color.r+CURRENT_COLOR.r,skytop_color.r+CURRENT_COLOR.r),1.0)*sky_rain_color,rain_f);

sky_far =lerp(lerp(skyline_day_color,skyline_sunset_color,fog_sunset_f),skyline_night_color,fog_night_f);
sky_far = lerp(sky_far,float4(float3(sky_far.r,sky_far.r,sky_far.r),1.0)*skyline_rain_color,rain_f);

sfog_color =lerp(lerp(fsky_day_color*0.79,fsky_sunset_color,fog_sunset_f),fsky_night_color,fog_night_f);
sfog_color = lerp(sfog_color,float4(float3(sfog_color.r,sfog_color.r,sfog_color.r),1.0)*fsky_rain_color,rain_f);

cloud_color =lerp(lerp(cloud_day_color,cloud_sunset_color,fog_sunset_f),cloud_night_color,fog_night_f);
cloud_color = lerp(cloud_color,float4(float3(cloud_color.r+CURRENT_COLOR.r,cloud_color.r+CURRENT_COLOR.r,cloud_color.r+CURRENT_COLOR.r),1.0)*cloud_rain_color,rain_f);

cloud_sh_color =lerp(lerp(cloud_day_sh_color,cloud_sunset_sh_color,fog_sunset_f),cloud_night_sh_color,fog_night_f);
cloud_sh_color = lerp(cloud_sh_color,float4(float3(cloud_sh_color.r,cloud_sh_color.r,cloud_sh_color.r),1.0)*cloud_rain_sh_color,rain_f);

sunmoon_color =lerp(lerp(sun_color,sun_sunset_color,fog_sunset_f),moon_color,fog_night_f);
sunmoon_color.a = 1.0-rain_f;

reflect_color =lerp(lerp(reflect_day_color,reflect_sunset_color,fog_sunset_f),reflect_night_color,fog_night_f);
reflect_color = lerp(reflect_color,float4(0.0,0.0,0.0,0.0),rain_f);

#ifdef UN_SH_LIGHT
w_light_color*=un_sh_light*0.5+1.0;
#endif

float3 c_pos =float3(PSInput.w_pos.x,PSInput.w_pos.y+1.0-fog_sunset_f*0.5,PSInput.w_pos.z);
  float3 np = normalize(c_pos);
  float sun = abs(1.0-length(np.yz));

  float sky_a =length(PSInput.w_pos);

float4 sky_color;


sky_color=lerp(skytop_color, sky_far, pow(clamp(sky_a*(2.0-fog_sunset_f*0.2),0.0,1.0),1.2+fog_sunset_f*0.5));
sky_color=lerp(sky_color, sfog_color,pow(clamp(sky_a*1.7,0.0,1.0),1.5+fog_sunset_f*0.5));

sky_color +=sun*sfog_color*(1.0-fog_night_f)*7.0;
#ifdef STAR
sky_color =lerp(sky_color,stars_color,starRender( PSInput.w_pos.xz*1000.0, 0.99)*fog_night_f*(1.0-rain_f));
#endif

sky_color.rgb =toneMap(sky_color.rgb,0.65);

sky_color=lerp(sky_color, FOG_COLOR,clamp(pow(sky_a*(1.05),3.0-fog_sunset_f*2.0),0.0,1.0));

if(UNWATER(FOG_COLOR,rain_f)){
sky_color =FOG_COLOR;
}

    PSOutput.color = sky_color;
}