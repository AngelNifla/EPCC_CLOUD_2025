import http from "k6/http";
import { sleep, check } from "k6";

export const options = {
  stages: [
    { duration: "2m", target: 20 },
    { duration: "4m", target: 60 },
    { duration: "2m", target: 0 },
  ],
};

const ALB = __ENV.ALB;

export default function () {
  if (Math.random() < 0.7) {
    http.get(`http://${ALB}/`);
    http.get(`http://${ALB}/movie/${Math.ceil(Math.random() * 5)}`);
  } else {
    const fid = Math.ceil(Math.random() * 8);
    const payload = { cantidad: "1" };
    const params = { headers: { "Content-Type": "application/x-www-form-urlencoded" } };
    http.post(`http://${ALB}/checkout/${fid}`, payload, params);
  }
  sleep(1);
}
