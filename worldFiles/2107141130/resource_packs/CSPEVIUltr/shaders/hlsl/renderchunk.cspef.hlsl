#include "ShaderConstants.fxh"
#include "util.fxh"

struct PS_Input
{
	float4 position : SV_Position;
	float3 w_pos : CSPE_w_pos;
	float3 v_pos : CSPE_v_pos;

#ifndef BYPASS_PIXEL_SHADER
	lpfloat4 color : COLOR;
	snorm float2 uv0 : TEXCOORD_0_FB_MSAA;
	snorm float2 uv1 : TEXCOORD_1_FB_MSAA;
#endif

#ifdef FOG
	float4 fogColor : FOG_COLOR;
#endif
};

struct PS_Output
{
	float4 color : SV_Target;
};

#include "function_lib.cspe"

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
float4 tex = TEXTURE_0.Sample(TextureSampler0, PSInput.uv0);
#include "variable.cspe"

light_f = pow(TEXTURE_1.Sample(TextureSampler1, float2(0.0,1.0)).r,2.0);

fog_f =length(-PSInput.v_pos)/ FAR_CHUNKS_DISTANCE;




rain_f =clamp((1.0-pow(FOG_CONTROL.y+0.1,5.0))*2.0,0.0,1.0);
night_f =clamp((0.6-light_f+clamp(0.6-light_f,0.0,1.0))*1.5,0.0,1.0);
sunset_f =clamp((1.0-light_f)*3.0,0.0,clamp(1.0-night_f-rain_f,0.0,1.0));
fog_night_f =pow(clamp(1.0-(FOG_COLOR.r+FOG_COLOR.b)*1.5,0.0,1.0),0.5);
fog_sunset_f =pow(clamp(1.0-(FOG_COLOR.b+FOG_COLOR.g),0.0,clamp(1.0-fog_night_f-rain_f,0.0,1.0)),0.5);




side_f=normalize(cross(ddx(PSInput.w_pos),ddy(PSInput.w_pos)));

side_y_f =clamp(abs(side_f.y),0.0,1.0);
side_x_f =clamp(abs(side_f.x),0.0,1.0);
side_z_f =clamp(abs(side_f.z),0.0,1.0);
side_xz_f =clamp(side_x_f+side_z_f,0.0,1.0);




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




f_sh_f =0.125;
x_sh_f =0.31;

dark_sh_f =pow(PSInput.uv1.y,1.0);

#ifdef SEASONS
f_sh_f =0.13;
x_sh_f =PSInput.color.a*3.0;
w_light_color*=1.25;
#endif

float c_torch_f =pow(PSInput.uv1.x,5.0)+PSInput.uv1.x*side_xz_f*0.1;

float tgrass_sh_f =clamp(side_f.x*side_f.z,0.0,1.0);

//float player_sh_f =clamp(playerShadowSet(PSInput.w_pos,PSInput.v_pos),0.0,1.0);

#ifdef BYPASS_PIXEL_SHADER
    PSOutput.color = float4(0.0f, 0.0f, 0.0f, 0.0f);
    return;
#else

#if USE_TEXEL_AA
	float4 diffuse = texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0 );
#else
	float4 diffuse = TEXTURE_0.Sample(TextureSampler0, PSInput.uv0);
#endif

#ifdef SEASONS_FAR
	diffuse.a = 1.0f;
#endif

#if USE_ALPHA_TEST
	#ifdef ALPHA_TO_COVERAGE
		#define ALPHA_THRESHOLD 0.05
	#else
		#define ALPHA_THRESHOLD 0.5
	#endif
	if(diffuse.a < ALPHA_THRESHOLD)
		discard;
#endif

float bright_diffuse =brightMap(diffuse.rgb);
float bright_color =brightMap(PSInput.color.rgb);

#if defined(BLEND)
	diffuse.a *= PSInput.color.a;
#endif

#if !defined(ALWAYS_LIT)
	//diffuse = diffuse * TEXTURE_1.Sample(TextureSampler1, PSInput.uv1);
#endif

#ifndef SEASONS
	#if !USE_ALPHA_TEST && !defined(BLEND)
		diffuse.a = PSInput.color.a;
	#endif	
	
if(PSInput.color.g * 1.9 >= PSInput.color.r + PSInput.color.b){
diffuse.rgb *= lerp(pow(PSInput.color.rgb,float3(0.5,0.5,0.5)),PSInput.color.rgb,clamp(pow(PSInput.color.g+0.4,3.0),0.0,1.0));
}
else{
diffuse.rgb *= pow(PSInput.color.rgb,float3(0.2,0.2,0.2));
}

#else
	float2 uv = PSInput.color.xy;
	diffuse.rgb *= lerp(1.0f, TEXTURE_2.Sample(TextureSampler2, uv).rgb*2.0f, PSInput.color.b);
	diffuse.rgb *= PSInput.color.aaa;
	diffuse.a = 1.0f;
#endif

//other_worldRender(w_pos,true);

f_sh_f =pow(clamp((PSInput.uv1.y+f_sh_f),(0.0),(1.0)),(100.0));
x_sh_f =pow(clamp((PSInput.color.g+1.5*(PSInput.color.g-PSInput.color.b)+x_sh_f),(0.0),(1.0)),(28.0-(1.0-(c_torch_f+f_sh_f))*25.0));

if(PSInput.uv1.y>=0.0&&PSInput.color.a==0.0){
x_sh_f = (min(pow((PSInput.color.g*2.3+PSInput.color.r*0.1+PSInput.color.b*1.2)*0.7,10.0)+sunset_f*0.54,1.0));
w_light_color*=1.2;
} 

float4 sh =float4(f_sh_f*x_sh_f,f_sh_f*x_sh_f,f_sh_f*x_sh_f,f_sh_f*x_sh_f);

#ifdef PLAYER_SHADOW
//sh =clamp(sh-player_sh_f,float4(0.0,0.0,0.0,0.0),float4(1.0,1.0,1.0,1.0));
#endif

sh =clamp(sh-side_y_f*sunset_f*0.5-(side_x_f-tgrass_sh_f*2.0),float4(0.0,0.0,0.0,0.0),float4(1.0,1.0,1.0,1.0));
sh =lerp(sh,sky_far*0.3+shadow_color,clamp(dark_sh_f*(1.0-sh.r),0.0,1.0));

#ifdef BLOCK_HIGHLIGHT
float3 block_highlight =highlight(PSInput.v_pos)*reflect_color.rgb*(sh.r+sunset_f*side_y_f*f_sh_f);
#else
float3 block_highlight =float3(0.0,0.0,0.0);
#endif
/*
#ifdef NORMAL_MAP
block_highlight =highlight(PSInput.v_pos)*reflect_color.rgb*(side_y_f*f_sh_f);
vec3 normal =normal_map(uv0);
float highlight_map =pow(brightMap(diffuse.rgb)+0.6,5.0);
normal.xyz = normal.rgb * 2.0 - 1.0;
vec3 N =normalize(normal.xyz);
vec3 L =normalize(vec3(-sunset_f,-1.0+sunset_f,0.0));

vec3 w_nor_light_color = sh.rgb*max(w_light_color.rgb*dot(N, L)*1.6,mix(dark_sh_color.rgb,sky_far.rgb*0.25+shadow_color.rgb,clamp(dark_sh_f,0.0,1.0)));
vec3 torch_nor_light_color =c_torch_f*lights_color.rgb*clamp(c_torch_f*3.0,0.0,1.0);
float reflect_nor_reduce_f =1.2-brightMap(w_nor_light_color.rgb);
#endif*/

w_light_color =max(sh*w_light_color,dark_sh_color);

float reflect_reduce_f =1.0-brightMap(w_light_color.rgb);

float3 torch_light_color =c_torch_f*lights_color.rgb*clamp(x_sh_f+c_torch_f*3.0,0.0,1.0);

diffuse.rgb =lerp(diffuse.rgb,float3(bright_diffuse,bright_diffuse,bright_diffuse), clamp(sh.r*night_f*0.7-c_torch_f*3.0,0.0,1.0));

#ifdef NORMAL_MAP
//diffuse.rgb *=w_nor_light_color+(torch_nor_light_color)*reflect_nor_reduce_f+highlight_map*block_highlight;
#else
diffuse.rgb *=w_light_color.rgb+(torch_light_color)*reflect_reduce_f+block_highlight;
diffuse.rgb +=w_light_color.rgb*w_light_color.a+c_torch_f*lights_color.rgb*0.05;
#endif

diffuse.rgb =toneMap(diffuse.rgb,0.65);

#ifdef NEW_FOG
diffuse.rgb = lerp(diffuse.rgb,lerp(deep_fog_color.rgb,lerp(FOG_COLOR.rgb*deep_fog_color.rgb,FOG_COLOR.rgb*sfog_color.rgb*float3(1.0,0.9,1.0)+highlight(PSInput.v_pos)*2.0,sh.r),PSInput.uv1.y),fog_f*(0.4-sh.r*0.1));
#endif

#ifdef BLEND
if((PSInput.color.a > 0.6&&PSInput.color.b>PSInput.color.r*1.1)||(PSInput.color.a > 0.95&&bright_color<0.4)){
diffuse.rgb =PSInput.color.rgb*0.5;
}
#endif

#ifdef FOG
	diffuse.rgb = lerp( diffuse.rgb, sfog_color.rgb, PSInput.fogColor.a );
#endif

	PSOutput.color = diffuse;

#ifdef VR_MODE
	// On Rift, the transition from 0 brightness to the lowest 8 bit value is abrupt, so clamp to 
	// the lowest 8 bit value.
	PSOutput.color = max(PSOutput.color, 1 / 255.0f);
#endif

#endif // BYPASS_PIXEL_SHADER
}