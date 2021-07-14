#include "ShaderConstants.fxh"

struct VS_Input {
	float3 position : POSITION;
	float4 color : COLOR;
	float2 uv0 : TEXCOORD_0;
	float2 uv1 : TEXCOORD_1;
#ifdef INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
};


struct PS_Input {
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
#ifdef GEOMETRY_INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	uint renTarget_id : SV_RenderTargetArrayIndex;
#endif
};


static const float rA = 1.0;
static const float rB = 1.0;
static const float3 UNIT_Y = float3(0, 1, 0);
static const float DIST_DESATURATION = 56.0 / 255.0; //WARNING this value is also hardcoded in the water color, don'tchange

#include "cspe_custom/cspe_option.txt"

ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput)
{
#ifndef BYPASS_PIXEL_SHADER
	PSInput.uv0 = VSInput.uv0;
	PSInput.uv1 = VSInput.uv1;
	PSInput.color = VSInput.color;
#endif

#ifdef AS_ENTITY_RENDERER
	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
		PSInput.position = mul(WORLDVIEWPROJ_STEREO[i], float4(VSInput.position, 1));
	#else
		PSInput.position = mul(WORLDVIEWPROJ, float4(VSInput.position, 1));
	#endif
		float3 worldPos = PSInput.position;
#else
		float3 worldPos = (VSInput.position.xyz * CHUNK_ORIGIN_AND_SCALE.w) + CHUNK_ORIGIN_AND_SCALE.xyz;
	
		// Transform to view space before projection instead of all at once to avoid floating point errors
		// Not required for entities because they are already offset by camera translation before rendering
		// World position here is calculated above and can get huge
	#ifdef INSTANCEDSTEREO
		int i = VSInput.instanceID;
	
		PSInput.position = mul(WORLDVIEW_STEREO[i], float4(worldPos, 1 ));
		PSInput.position = mul(PROJ_STEREO[i], PSInput.position);
	
	#else
		PSInput.position = mul(WORLDVIEW, float4( worldPos, 1 ));
		PSInput.position = mul(PROJ, PSInput.position);
	#endif

#endif

#ifdef GEOMETRY_INSTANCEDSTEREO
		PSInput.instanceID = VSInput.instanceID;
#endif 
#ifdef VERTEXSHADER_INSTANCEDSTEREO
		PSInput.renTarget_id = VSInput.instanceID;
#endif

PSInput.w_pos=VSInput.position.xyz;
PSInput.v_pos=worldPos.xyz;

float rain_f =clamp((1.0-pow(FOG_CONTROL.y+0.1,5.0))*2.0,0.0,1.0);

float3 wav_pos = float3(0.0,0.0,0.0);

float2 t_pos =floor(float2(PSInput.uv0.x * 32.0, PSInput.uv0.y * 32.0));

#ifdef ALPHA_TEST

#ifdef PLANT_WAVE

float wind =max(sin((PSInput.w_pos.x+PSInput.w_pos.z)*0.5+TIME*2.0),0.3*rain_f)*PSInput.uv1.y*(1.0+rain_f*1.5);

wav_pos.x = (sin(TIME*4.0 + PSInput.w_pos.x*1.2)+sin(TIME*3.0 + PSInput.w_pos.x*0.8) + sin(TIME*6.2 + PSInput.w_pos.z*2.5))*0.04;
wav_pos.x *= pow(1.0-(PSInput.uv0.y * 32.0-t_pos.y),2.0)*wind;

if((PSInput.color.r==PSInput.color.g&&PSInput.color.g==PSInput.color.b)||(t_pos.y==15.0)||(PSInput.color.r>PSInput.color.g*2.0)){
wav_pos = float3(0.0,0.0,0.0);
}
else if((PSInput.color.r!=PSInput.color.g&&PSInput.color.g!=PSInput.color.b)){
wav_pos *= 3.0;
if(PSInput.uv1.y>=0.0&&PSInput.color.a==0.0){
wav_pos.x = (sin(TIME*6.0 + PSInput.w_pos.z*PSInput.w_pos.x*2.0)*0.02+sin(TIME*5.0 + PSInput.w_pos.z*PSInput.w_pos.x*3.5)*0.03-sin(TIME*8.0 + PSInput.w_pos.z*PSInput.w_pos.x*1.5)*0.02);
wav_pos.y = (sin(TIME*6.3 + PSInput.w_pos.z*PSInput.w_pos.x*2.01)+sin(TIME*5.0+ PSInput.w_pos.z*PSInput.w_pos.x*3.5) + sin(TIME*8.0 + PSInput.w_pos.x*PSInput.w_pos.z*1.5))*0.01;
wav_pos*=wind;
}

}
else{
wav_pos = float3(0.0,0.0,0.0);
}

/*
if((PSInput.color.r==PSInput.color.g&&PSInput.color.g==PSInput.color.b)||(t_pos.y==15.0)||(PSInput.color.r>PSInput.color.g*2.0)){
wav_pos = float3(0.0,0.0,0.0);
}
else if((PSInput.color.r!=PSInput.color.g&&PSInput.color.g!=color.b)){
wav_pos *= 3.0;

if(t_pos.y==8.0&&t_pos.x<=23.0){ //grass bot
wav_pos.x = (sin(TIME*4.0 + PSInput.w_pos.x*1.2)+sin(TIME*3.0 + PSInput.w_pos.x*0.8) + sin(TIME*6.2 + PSInput.w_pos.z*2.5))*0.04;
wav_pos *= wind*1.68;
}

if(PSInput.uv1.y>=0.0&&PSInput.color.a==0.0){//leaves
wav_pos.x = (sin(TIME*1.1+ PSInput.w_pos.x*1.4)+sin(TIME*2.1+ PSInput.w_pos.x*1.51) - sin(TIME*5.2 - PSInput.w_pos.z*2.0))*0.017;
wav_pos.y = (sin(TIME*4.3 + PSInput.w_pos.x*4.01)+sin(TIME*3.9+ PSInput.w_pos.x*3.5) + sin(TIME*6.2 + PSInput.w_pos.z*5.0))*0.005;
wav_pos*=wind*2.0;
}
else if(t_pos.y==20.0&&t_pos.x<=11.0){
wav_pos.x = (sin(TIME*1.1+ PSInput.w_pos.x*1.4)+sin(TIME*2.1+ PSInput.w_pos.x*1.51) - sin(TIME*5.2 - PSInput.w_pos.z*2.0))*0.017;
wav_pos.y = (sin(TIME*4.3 + PSInput.w_pos.x*4.01)+sin(TIME*3.9+ PSInput.w_pos.x*3.5) + sin(TIME*6.2 + PSInput.w_pos.z*5.0))*0.005;
wav_pos*=wind;
}

}
else{
wav_pos = float3(0.0,0.0,0.0);
}
*/
#endif

PSInput.position.xyz +=wav_pos.xyz;

#endif

///// find distance from the camera

#if defined(FOG) || defined(BLEND)
	#ifdef FANCY
		float3 relPos = -worldPos;
		float cameraDepth = length(relPos);
	#else
		float cameraDepth = PSInput.position.z;
	#endif
#endif

	///// apply fog

#ifdef FOG
	float len = cameraDepth / RENDER_DISTANCE;
#ifdef ALLOW_FADE
	len += RENDER_CHUNK_FOG_ALPHA.r;
#endif

	PSInput.fogColor.rgb = FOG_COLOR.rgb;
	PSInput.fogColor.a = clamp((len - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 0.0, 1.0);

#endif


}
